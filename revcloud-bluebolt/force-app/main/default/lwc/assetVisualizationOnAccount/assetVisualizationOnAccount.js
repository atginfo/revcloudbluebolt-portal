/**
 * @description       : Create a chart component to display bar charts from a JSON object
 * @author            : David Sam
 * @group             : Cognizant
 * @ticket            : CIBGCF-34
 * @last modified on  : 07-01-2025
 * @last modified by  : Frank Berni
**/
import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id'; // Get the current userId
import { refreshApex } from '@salesforce/apex';
import getAssetAndReletionships from '@salesforce/apex/AssetVisualizationOnAccount_lwc.getAssetAndReletionships';

// Unused imports
import charjsv1 from '@salesforce/resourceUrl/charjsv1';
import { loadScript } from 'lightning/platformResourceLoader'; // Load the chart.js library as a static resource from Salesforce
import getAssetAmountDetails from '@salesforce/apex/AssetVisualizationOnAccount_lwc.getAssetAmountDetails';
import getAssetsList from '@salesforce/apex/AssetVisualizationOnAccount_lwc.getAssetsList';
import { RefreshEvent } from "lightning/refresh";
import LightningPrompt from 'lightning/prompt';
import getAssetAndRelatedAssets from '@salesforce/apex/AssetVisualizationOnAccount_lwc.getAssetAndRelatedAssets';
import getAssets from '@salesforce/apex/AssetVisualizationOnAccount_lwc.getAssets';
import StartDate from '@salesforce/schema/Contract.StartDate';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';



  //--------------------------------------------------

    //Build the table header
    const columns = [
        {
            type: "text",
            fieldName: 'Name',
            label: "Asset Name",   
            sortable: true,
            wrapText: "true",
            // NEW increase width to 300
            initialWidth: 300,
        },
        // NEW Removed Asset Id column
        {
            type: "currency",
            fieldName: 'Mrr',
            // NEW Updated label name
            label: "Recurring Amount",
            sortable: true,
            wrapText: "true",
            cellAttributes: {
                class: 'amount-cell'
            },
            typeAttributes: {
                currencyCode: 'USD',
                minimumFractionDigits: 2,
            },
            // NEW increase width to 200
            initialWidth: 200,
        },
        {
            type: "text",
            fieldName: 'Billing_Frequency2__c',
            label: "Billing Frequency", 
            sortable: true,  
            wrapText: "true",
            cellAttributes: {
                iconName: 'utility:clock',
                iconAlternativeText: 'Billing Frequency',
            },
            initialWidth: 160,
        },
        { 
            // NEW updated type to date-local, keeps date more absolute based on current time zone
            type: "date-local",
            fieldName: 'StartDate',
            label: "Start Date",
            sortable: true,
            initialWidth: 160,
            cellAttributes: {
                iconName: 'utility:event',
                iconAlternativeText: 'Start Date',
            },
        },
        { 
            // NEW updated type to date-local, keeps date more absolute based on current time zone
            type: "date-local",
            fieldName: 'EndDate',
            label: "End Date",
            sortable: true,
            cellAttributes: {
                iconName: 'utility:event',
                iconAlternativeText: 'End Date',
            },
            initialWidth: 160,
        },
        {
            type: "number",
            fieldName: 'Quantity',
            label: "Quantity",
            sortable: true,
            cellAttributes: {
                iconName: 'utility:quantity',
                iconAlternativeText: 'Quantity',
            },
            initialWidth: 120,
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: { fieldName: 'rowActions' },
                menuAlignment: 'right', // Align the menu to the right
            },

        },

    ];

    const actions = [
        { label: 'Amend', name: 'amend' }
    ];

  

  function isDateInRange(date, start, end) {
    if (!date || !start || !end) return false;
    const d = new Date(date);
    return d >= new Date(start) && d <= new Date(end);
}

// use spread operator to set the default values or track the values from the javascript or use a function
//          ie: this.object = {...this.setDefaultValues(), "objectPropertyToBeTracked":event.target.value},;
export default class AssetVisualizationOnAccount extends LightningElement {

    @track isChartJsInitialized = false;
    @track isLoading = false;
    assets;

    //Tree-grid Tracked values.
    @track columns = columns;
    @track actions = actions;
    @track selectedAssetId;
    @track parseData;
    @track expandedRows = [];
    @track sortBy = 'Name'; // Default sort field
    @track sortDirection = 'asc'; // Default sort direction
    @track _originalGridData = [];
    @track expandCollapseLabel = 'Expand All';
    @track validityDate = new Date().toISOString().slice(0, 10); // yyyy-mm-dd
    // NEW Removed track variable for dynamicTitle added getter instead
    flowApiName = "Clone_Amend_Renew_and_Cancel_Assets";
    @track recentlyUpdatedAssetId; // Add this tracked property
    renderFlow = false;
    
    currentUserId = Id;

    wiredAssetsResult;
    
    @track gridData = [];

    //===========================================================
    @track expandCollapseLabel = 'Expand All';
    // ...existing code...

    // Wire method with parameters
   @wire(getAssetAndReletionships, { userId: '$currentUserId', assetValidityDate: '$validityDate' })
   wiredAssets(result) {
    this.wiredAssetsResult = result;
    if (result.data) {
        const assets = JSON.parse(JSON.stringify(result.data));
        const assetMap = {};
        const parentIds = new Set();
        const childIds = new Set();
        const bundles = [];
        const standalones = [];
        const selectedDate = this.validityDate;

        // Helper to merge AssetStatePeriod fields into asset row
        function mergeStatePeriodFields(asset, statePeriod) {
            return {
                ...asset,
                Mrr: statePeriod.Mrr || null,
                Billing_Frequency2__c: asset.Billing_Frequency2__c || '',
                StartDate: statePeriod.StartDate || null,
                EndDate: statePeriod.EndDate || null,
                Quantity: statePeriod.Quantity || null,
                _children: []
            };
        }

        // Helper to map asset to grid fields (if no valid ASP)
        function mapAssetFields(asset) {
            return {
                // NEW updated to Id instead of AssetId
                Id: asset.Id,
                // NEW remove '--' at end of Name
                Name: asset.Name,
                Mrr: asset.Mrr || null,
                Billing_Frequency2__c: asset.Billing_Frequency2__c || '',
                StartDate: asset.StartDate || null,
                EndDate: asset.EndDate || null,
                Quantity: asset.Quantity || null,
                _children: []
            };
        }

        // Build asset map for quick lookup, merge AssetStatePeriod fields if valid
        assets.forEach(asset => {
            let asp = asset.AssetStatePeriods;
            if (typeof asp === 'string') {
                try { asp = JSON.parse(asp); } catch { asp = []; }
            }
            asp = asp || [];
            const aspFiltered = asp.filter(sp => isDateInRange(selectedDate, sp.StartDate, sp.EndDate));
            
            if (aspFiltered.length > 0) {
                assetMap[asset.Id] = mergeStatePeriodFields(mapAssetFields(asset), aspFiltered[0]);
            } else {
                assetMap[asset.Id] = null;
            }
        });

        // Build bundles and track parent/child relationships
        assets.forEach(asset => {
            if (asset.RelatedAssets) {
                let relatedArr = asset.RelatedAssets;
                if (typeof relatedArr === 'string') {
                    try { relatedArr = JSON.parse(relatedArr); } catch { relatedArr = []; }
                }
                if (Array.isArray(relatedArr)) {
                    relatedArr.forEach(rel => {
                        const parentId = rel.AssetId;
                        const childId = rel.RelatedAssetId;
                        parentIds.add(parentId);
                        childIds.add(childId);
                        // Add child asset to parent bundle if both have valid ASPs
                        if (assetMap[parentId] && assetMap[childId]) {
                            if (!assetMap[parentId]._children.find(c => c.AssetId === assetMap[childId].AssetId)) {
                                assetMap[parentId]._children.push(assetMap[childId]);
                            }
                        }
                    });
                }
            }
        });

        Object.keys(assetMap).forEach(id => {
            const asset = assetMap[id];
            if (asset && (!asset._children || asset._children.length === 0)) {
                // Remove the _children property if empty
                delete asset._children;
            }
        });

        // Add parent assets with valid ASPs to bundles
        parentIds.forEach(parentId => {
            if (assetMap[parentId]) {
                bundles.push(assetMap[parentId]);
            }
        });

        // Find standalones: assets not referenced as child or parent in any bundle
        assets.forEach(asset => {
            if (!parentIds.has(asset.Id) && !childIds.has(asset.Id)) {
                if (assetMap[asset.Id]) {
                    standalones.push(assetMap[asset.Id]);
                }
            }
        });

        // Combine bundles and standalones for the tree grid
        this.gridData = [...bundles, ...standalones];

        this.gridData = [...bundles, ...standalones].map(row => ({
            ...row,
            rowActions: [
                // { label: 'Add', name: 'add' },
                { label: 'Amend', name: 'amend' }
            ]
        }));

    } else if (result.error) {
        this.gridData = [];
    }
}

    // Handler for date input change
    handleInputChange(event) {
        this.validityDate = event.target.value;
        return refreshApex(this.wiredAssetsResult); 
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedAssetId = selectedRows.length > 0 ? selectedRows[0].AssetId : null;
    }

    toggleExpandCollapseAll() {
        // Collect all keys (using Name as key-field)
        const allKeys = [];
        function collectKeys(nodes) {
            if (!Array.isArray(nodes)) return; // <-- Prevents undefined errors
            
            nodes.forEach(node => {
                // NEW Updated to use Id instead of Name
                if (node && node.Id) {
                    allKeys.push(node.Id);
                }
                if (node && Array.isArray(node._children) && node._children.length > 0) {
                    collectKeys(node._children);
                }
            });
        }

        // NEW using collectKeys on gridData and isFullyExpanded boolean to keep track of status of tree-grid
        collectKeys(this.gridData);
        const isFullyExpanded = this.expandedRows.length === allKeys.length && allKeys.every(id => this.expandedRows.includes(id));
        this.expandedRows = isFullyExpanded ? [] : allKeys;
        this.expandCollapseLabel = isFullyExpanded ? 'Expand All' : 'Collapse All';

    }

    doSorting(event) {
        const fieldName = event.detail.fieldName;
        let sortDirection = 'asc';

        // Toggle sort direction if the same column is clicked
        if (this.sortBy === fieldName) {
            sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        }

        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        // Deep copy to avoid mutating original data
        let parseData = JSON.parse(JSON.stringify(this.gridData));
        // Helper to sort recursively
        function sortRecursive(data) {
            data.sort((a, b) => {
                let x = a[fieldname] || '';
                let y = b[fieldname] || '';
                if (typeof x === 'string') x = x.toLowerCase();
                if (typeof y === 'string') y = y.toLowerCase();
                return direction === 'asc' ? (x > y ? 1 : x < y ? -1 : 0) : (x < y ? 1 : x > y ? -1 : 0);
            });
            data.forEach(item => {
                if (item._children && item._children.length > 0) {
                    sortRecursive(item._children);
                }
            });
        }
        sortRecursive(parseData);
        this.gridData = parseData;
    }

    getRowActions(row, doneCallback) {
        console.log('getRowActions called for row: ' );
        console.log('getRowActions called for row: ' + JSON.stringify(row));
        const actions = [
            { 
                label: 'Amend', name: 'amend'
            }
        ];
        doneCallback(actions);
    }

    @api
    flowInputVariables = [];

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        const formatter = new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
        });

        if (actionName === 'add' || actionName === 'amend') {
            // NEW replaced with row.Id
            this.selectedAssetId = row.Id;
            console.log('Selected AssetId: ' + this.selectedAssetId);
            // Launch the flow, passing AssetId and other necessary variables
            this.flowApiName = "Clone_Amend_Renew_and_Cancel_Assets";
            console.log('Flow Input Variables: 123 - Date: ' );
            this.flowInputVariables = [
                {
                    name: 'recordIds',
                    type: 'String',
                    value: this.selectedAssetId
                },
                {
                    name: 'actionType',
                    type:'String',
                    value: 'Amend'
                }
            
            ];
            console.log('Flow Input Variables: ' + JSON.stringify(this.flowInputVariables));
            this.renderFlow = true;
            // Optionally, you can set a variable to distinguish between Add and Amend
        }

    }

    get inputVariables() {
        return [
            {
                name: 'recordIds',
                type: 'text',
                value: this.selectedAssetId
            },
            {
                name: 'actionType',
                type:'text',
                value: 'Amend'
            }
        
        ];
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            // set behavior after a finished flow interview

            this.renderFlow = false;

            // Fire toast AFTER modal is closed
            setTimeout(() => {
            // Make the refresh work with after the amend.
            refreshApex(result);
            // Assume this.selectedAssetId is the updated row
            this.recentlyUpdatedAssetId = this.selectedAssetId;
            refreshApex(this.wiredAssetsResult).then(() => {
                // Optionally, you can clear the highlight after a timeout
                setTimeout(() => {
                    this.recentlyUpdatedAssetId = null;
                    window.reload();
                }, 3000); // highlight for 3 seconds
            });

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'The amendment has been successfully completed',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            }, 100); // Small delay to ensure modal is closed
            
            
            
        }
    }

    handleFinish(event) {
        console.log('Flow Finished', event.detail);

        // Assume this.selectedAssetId is the updated row
        this.recentlyUpdatedAssetId = this.selectedAssetId;
        refreshApex(this.wiredAssetsResult).then(() => {
            // Optionally, you can clear the highlight after a timeout
            setTimeout(() => {
                this.recentlyUpdatedAssetId = null;
            }, 3000); // highlight for 3 seconds
        });
        this.renderFlow = false;
    }

    closeModal() {
        this.renderFlow = false;
    }

    // NEW added getter for title 
    get dynamicTitle() {
        return `My Current Assets as of ${this.validityDate}`;
    }

    get gridDataWithHighlight() {
        return (this.gridData || []).map(row => ({
            ...row,
            _rowClass: row.AssetId === this.recentlyUpdatedAssetId ? 'highlight-row' : ''
        }));
    }

    rowClass(row) {
        return row._rowClass;
    }


    
}