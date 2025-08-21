import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBillingSchedules from '@salesforce/apex/BillNowController.getBillingSchedules';
import getFieldSetFields from '@salesforce/apex/FieldSetHelper.getFieldSetFields';
import generateInvoices from '@salesforce/apex/InvoiceGenerator.generateInvoices';
import generateInvoicesWithTargetDate from '@salesforce/apex/InvoiceGenerator.generateInvoicesWithTargetDate';

export default class BillNow extends LightningElement {
    @api recordId; // Order Id
    @track billingSchedules = [];
    @track columns = [];
    @track isLoading = true;
    @track selectedRows = [];
    @track disableButton = true;

    connectedCallback() {
        this.loadColumns();
    }

    loadColumns() {
        getFieldSetFields({ objectName: 'BillingSchedule', fieldSetName: 'Bill_Now_Field_Set' })
            .then(fields => {
                this.columns = [
                    { label: 'Billing Schedule Number', fieldName: 'BillingScheduleLink', type: 'url', typeAttributes: { label: { fieldName: 'BillingScheduleNumber' }, target: '_blank' } },
                    { label: 'Order Item Number', fieldName: 'OrderItemLink', type: 'url', typeAttributes: { label: { fieldName: 'OrderItemNumber' }, target: '_blank' } },
                    { label: 'Product', fieldName: 'ProductLink', type: 'url', typeAttributes: { label: { fieldName: 'Product2Name' }, target: '_blank' } },
                    ...fields.map(field => ({ label: field, fieldName: field }))
                ];
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error', 'Error loading columns', 'error');
                console.error('Error loading columns:', error);
                this.isLoading = false;
            });
    }

    @wire(getBillingSchedules, { orderId: '$recordId' })
    wiredBillingSchedules({ error, data }) {
        if (data) {
            console.log('Billing Schedules:', data);
            this.billingSchedules = data;
            console.log('Processed Billing Schedules:', this.billingSchedules);
        } else if (error) {
            this.showToast('Error', 'Error fetching billing schedules', 'error');
            console.error('Error fetching billing schedules:', error);
        }
    }

    handleInputChange(event) {
        this.dateInputValue = event.target.value;
        console.log('this.dateInputValue is: ', this.dateInputValue);
        this.disableButton = false;
        console.log('this.disableButton is: ', this.disableButton);

    }

    handleRowSelection(event) {
        if (this.dataInputValuue !== '') {
            this.disableButton = true;
            console.log('this.disableButton is: ', this.disableButton);
        } 
        this.selectedRows = event.detail.selectedRows;
        console.log('Selected Rows:', this.selectedRows);
    }

    handleGenerateInvoices() {

        const selectedBillingScheduleIds = this.selectedRows.map(row => row.Id);
        console.log('this.dateInputValue from the handleGEnInvoices is: ', this.dateInputValue);
        const theTargetDate = this.dateInputValue;
        console.log('theTargetDate is: ', theTargetDate);
        if (selectedBillingScheduleIds.length > 0) {
          //  generateInvoices({ billingScheduleIds: selectedBillingScheduleIds })
            generateInvoicesWithTargetDate({ billingScheduleIds: selectedBillingScheduleIds, targetDate: theTargetDate })
                .then(() => {
                    this.showToast('Success', 'Invoicing in process..', 'success');
                })
                .catch(error => {
                    this.showToast('Error', 'Error initiating invoice generation', 'error');
                    console.error('Error initiating invoice generation:', error);
                });
        } else {
            this.showToast('Warning', 'No billing schedules selected', 'warning');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}