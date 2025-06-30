import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInvoiceLines from '@salesforce/apex/ShowInvoiceLinesController.getInvoiceLines';
import getFieldSetFields from '@salesforce/apex/FieldSetHelper.getFieldSetFields';

export default class ShowInvoiceLinesOnOrder extends LightningElement {
    @api recordId; // Record Id (Order Id for now)
    @track invoiceLines = [];
    @track columns = [];
    @track isLoading = true;

    connectedCallback() {
        this.loadColumns();
    }

    loadColumns() {
        getFieldSetFields({ objectName: 'InvoiceLine', fieldSetName: 'Show_Invoice_Lines_On_Order' })
            .then(fields => {
                this.columns = [
                    { label: 'Billing Schedule Number', fieldName: 'billingScheduleLink', type: 'url', typeAttributes: { label: { fieldName: 'billingScheduleNumber' }, target: '_blank' } },
                    { label: 'Product', fieldName: 'productLink', type: 'url', typeAttributes: { label: { fieldName: 'productName' }, target: '_blank' } },
                    { label: 'Invoice Number', fieldName: 'invoiceLink', type: 'url', typeAttributes: { label: { fieldName: 'invoiceNumber' }, target: '_blank' } },
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

    @wire(getInvoiceLines, { recordId: '$recordId' })
    wiredInvoiceLines({ error, data }) {
        if (data) {
            this.invoiceLines = data.map(line => {
                return {
                    ...line,
                    productLink: `/lightning/r/Product2/${line.Product2Id}/view`,
                    productName: line.Product2.Name,
                    billingScheduleLink: `/lightning/r/BillingSchedule/${line.BillingScheduleId}/view`,
                    invoiceLink: `/lightning/r/Invoice/${line.InvoiceId}/view`,
                    invoiceNumber: line.Invoice.DocumentNumber,
                    billingScheduleNumber: line.BillingSchedule.BillingScheduleNumber
                };
            });
        } else if (error) {
            this.showToast('Error', `Error fetching invoice lines: ${error.body.message}`, 'error');
            console.error('Error fetching invoice lines:', error);
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