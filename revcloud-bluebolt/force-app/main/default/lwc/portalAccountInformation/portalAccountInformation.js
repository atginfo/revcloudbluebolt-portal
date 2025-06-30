import { LightningElement, track, wire } from 'lwc';
import getAccountDetails from '@salesforce/apex/PortalAccountInformation.getAccountDetails';
import getContactDetails from '@salesforce/apex/PortalAccountInformation.getContactDetails';
import CONTACT_NAME from '@salesforce/schema/Contact.Name';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import ACCOUNTID_FIELD from '@salesforce/schema/Contact.AccountId';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import FAX_FIELD from '@salesforce/schema/Contact.Fax';
import DEPARTMENT_FIELD from '@salesforce/schema/Contact.Department';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Table columns - FirstName, LastName, Email, Phone
const columns = [
        {
            type: "text",
            fieldName: 'Salutation',
            label: "Salutation",   
            sortable: true,
            // cellAttributes: {
            //     class: 'slds-text-color_success slds-text-title_caps',
            // },
            initialWidth: 80,
        },
        {
            type: "text",
            fieldName: 'FirstName',
            label: "FirstName",   
            sortable: true,
            // cellAttributes: {
            //     class: 'slds-text-color_success slds-text-title_caps',
            // },
            initialWidth: 120,
        },
        {
            type: "text",
            fieldName: 'LastName',
            label: "Last Name", 
            sortable: true,  
            // cellAttributes: {
            //     iconName: 'utility:asset',
            //     iconAlternativeText: 'Asset Id',
            // },
            initialWidth: 120,
        },
        {
            type: "email",
            fieldName: 'Email',
            label: "Email",
            sortable: true,
            // cellAttributes: {
            //     // iconName: 'utility:money',
            //     // iconAlternativeText: 'Monthly Recurring Revenue',
            //     class: 'amount-cell'
            // },
            // typeAttributes: {
            //     currencyCode: 'USD',
            //     minimumFractionDigits: 2,
            // },
            initialWidth: 250,
        },
        {
            type: "phone",
            fieldName: 'Phone',
            label: "Phone Number", 
            sortable: true,  
            cellAttributes: {
                iconName: 'utility:phone',
                iconAlternativeText: 'Phone Number',
            },
            initialWidth: 160,
        },
        {
            type: "Fax",
            fieldName: 'Fax',
            label: "Fax Number", 
            sortable: true,  
            cellAttributes: {
                iconName: 'utility:fax',
                iconAlternativeText: 'Fax Number',
            },
            initialWidth: 160,
        },
        {
            type: "text",
            fieldName: 'OwnerName',
            label: "Contact Owner", 
            sortable: true,  
            // cellAttributes: {
            //     iconName: 'utility:phone',
            //     iconAlternativeText: 'Phone Number',
            // },
            initialWidth: 160,
        },
        {
            type: "text",
            fieldName: 'AccountName',
            label: "Account Name", 
            sortable: true,  
            // cellAttributes: {
            //     iconName: 'utility:phone',
            //     iconAlternativeText: 'Phone Number',
            // },
            initialWidth: 160,
        },
        { 
            type: "text",
            fieldName: 'Department',
            label: "Department",
            sortable: true,
            initialWidth: 160,
        },
        // { 
        //     type: "date",
        //     fieldName: 'EndDate',
        //     label: "End Date",
        //     sortable: true,
        //     cellAttributes: {
        //         iconName: 'utility:event',
        //         iconAlternativeText: 'End Date',
        //     },
        //     initialWidth: 160,
        // },
        // {
        //     type: "number",
        //     fieldName: 'Quantity',
        //     label: "Quantity",
        //     sortable: true,
        //     cellAttributes: {
        //         iconName: 'utility:quantity',
        //         iconAlternativeText: 'Quantity',
        //     },
        //     initialWidth: 120,
        // },
        {
            type: 'action',
            typeAttributes: {
                rowActions: { fieldName: 'rowActions' },
                menuAlignment: 'right', // Align the menu to the right
            },

        },

    ];

export default class PortalAccountInformation extends LightningElement {

    // Contact Display Items
    @track dynamicAccountTitle = '';
    columns = columns;
    @track tableData;
    ACCOUNTID_FIELD = ACCOUNTID_FIELD; // Used to set the AccountId field in the contact creation modal

    // Create contacts items
    renderModal = false;
    objectApiName = CONTACT_OBJECT;
    fields = [CONTACT_NAME, EMAIL_FIELD, PHONE_FIELD, FAX_FIELD, DEPARTMENT_FIELD, ACCOUNTID_FIELD]; //FIRSTNAME_FIELD, LASTNAME_FIELD, ACCOUNT_NAME

    @wire(getContactDetails, {})
    getContactDetails(result) {
        if (result.error) {
            console.error(' There was an error while fetching your account details: ' + JSON.stringify(result.error));
        }
        else if (result.data) {
            console.log('result.data: ' + JSON.stringify(result.data));
            const dataMapping = result.data.map(contact => {
                return {
                    ...contact,
                    AccountName: contact.Account && contact.Account.Name ? contact.Account.Name : 'N/A',
                    OwnerName: contact.Owner && contact.Owner.Name ? contact.Owner.Name : 'N/A',
                    rowActions: [
                        { label: 'Edit Contact', name: 'edit_contact' },
                        { label: 'Delete Contact', name: 'delete_contact' }
                    ]
                };
            });
            this.tableData = dataMapping;
            // Optionally set dynamicAccountTitle if needed
            this.dynamicAccountTitle = 'Contact list for the account: ' + (dataMapping[0]?.AccountName || '');
            console.log('dataMapping: ' + JSON.stringify(dataMapping));
        }
    }

    openModal(event) {
        this.renderModal = true;
        console.log('ACCOUNT_NAME: ' + JSON.stringify(ACCOUNT_NAME));
    }
    cancelModal(event) {
        this.renderModal = false;
    }
    closeModal(event) {
        this.renderModal = false;
    }
    handleError(event) {
        console.error('There was an error while creating the contact: ' + JSON.stringify(event.detail.error));
        const toastForError = new ShowToastEvent({
            title: 'Error Creating Contact',
            message: 'There was an error while creating the contact: ' + event.detail.error.body.message,
            variant: 'error'
        });
        this.dispatchEvent(toastForError);
    }

    handleSuccess(event) {
        const tostForSuccessfullContactCreation = new ShowToastEvent({
            title: 'Contact Successfully Created',
            message: 'Contact ' + event.detail.fields.FirstName.value + ' ' + event.detail.fields.LastName.value + ' with the ID' + 
                    event.detail.ID + ' has been successfully created.',
            variant: 'success'

        });
        this.dispatchEvent(tostForSuccessfullContactCreation);
    }

//     @wire(getContactDetails, {})
//     getContactDetails(result) {
//         if (result.error) {
//             console.error(' There was an error whule fetching your account details: ' + JSON.stringify(result.error));
//         }
//         else if (result.data) {
//             console.log('result.data: ' + JSON.stringify(result.data));
//             const dataMapping = result.data.map(contact => {
//                 return {
//                     ...contact,
//                     AccountName: contact.Account.Name ? contact.Account.Name : 'N/A',
//                     OwnerName: contact.Owner.Name ? contact.Owner.Name : 'N/A'
//                     // , 
//                     // rowActions: [
//                     //     //{ label: 'View Contact', name: 'view_contact' },
//                     //     { label: 'Edit Contact', name: 'edit_contact' },
//                     //     { label: 'Delete Contact', name: 'delete_contact' }
//                     // ]
//                 };
//             });
//             console.log('dataMapping: ' + JSON.stringify(dataMapping));
//             // this.tableData = result.data;
//             this.tableData = dataMapping;
//             //this.accountName = this.Data.Name;
//             //this.dynamicAccountTitle = 'Contact list for the account: ' + ACCOUNT_NAME;
//             //console.log('dynamicAccountTitle: ' + dynamicAccountTitle);
//             console.log('dataMapping: ' + JSON.stringify(dataMapping));
//             console.log('This.tableData: ' + JSON.stringify(this.tableData));
//         }
//     }

//     // tmpName = Object.assign({}, {AssetId: tempName.AssetId, Name: tempName.Asset.Name, Amount: tempName.Mrr,
//     //                         Billing_Frequency2__c: tempName.Asset.Billing_Frequency2__c,StartDate: tempName.StartDate, EndDate: tempName.EndDate, Quantity: tempName.Quantity,
//     //                         });
}