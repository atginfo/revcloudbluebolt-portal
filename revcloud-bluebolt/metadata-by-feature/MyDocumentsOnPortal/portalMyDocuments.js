import { LightningElement, api,track,wire } from 'lwc';
import getMyInvoicesDocuments from '@salesforce/apex/PortalMyDocuments.getMyInvoicesDocuments';
import getAccountQuoteDocuments from '@salesforce/apex/PortalMyDocuments.getAccountQuoteDocuments';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Columns for the displaing the invoice documents
// const invoiceColumns = [
//     { label: 'Title', fieldName: 'ContentDocument.Title', type: 'text' },
//     { label: 'File Type', fieldName: 'ContentDocument.FileType', type: 'text' },
//     {
//         label: 'Download',
//         type: 'url',
//         fieldName: 'downloadUrl',
//         typeAttributes: { label: 'Download', target: '_blank' }
//     }
// ];

const quoteColumns = [
    { label: 'Title', fieldName: 'Title', type: 'text' },
    { label: 'File Type', fieldName: 'FileType', type: 'text' },
    {
        label: 'Download',
        type: 'url',
        fieldName: 'downloadUrl',
        typeAttributes: { label: 'Download', target: '_blank' }
    }
];

export default class PortalMyDocuments extends LightningElement {


    // @track invoiceDocuments = [];
    // @track invoiceDocumentsError;

    // @wire(getMyInvoicesDocuments, { accountId: '$recordId' }) // recordId should be set to the current Account Id
    // wiredMyInvoicesDocuments(result) {
    //     if (result.error) {
    //         this.invoiceDocumentsError = result.error;
    //         this.invoiceDocuments = [];
    //         console.error('Error fetching invoice documents:', result.error);
    //     } else if (result.data) {
    //         this.invoiceDocuments = result.data;
    //         this.invoiceDocumentsError = undefined;
    //         // Optionally, map or format data here for your UI
    //         console.log('Fetched invoice documents:', result.data);
    //     }

    //     this.invoiceDocuments = result.data.map(doc => ({
    //         ...doc,
    //         downloadUrl: `/sfc/servlet.shepherd/document/download/${doc.ContentDocument.LatestPublishedVersionId}`
    //     }));
    // }

    @api recordId; // Account Id passed from parent or context
    @track quoteDocuments = [];
    @track quoteDocumentsError;
    quoteColumns = quoteColumns;

    @wire(getAccountQuoteDocuments, {})
    wiredAccountQuoteDocuments(result) {
        if (result.error) {
            this.quoteDocumentsError = result.error;
            this.quoteDocuments = [];
            console.error('Error fetching quote documents:', result.error);
        } else if (result.data) {

            console.log('result.data: ' + JSON.stringify(result.data));
            // Map ContentDocument fields for datatable
            this.quoteDocuments = result.data.map(docLink => ({
                Id: docLink.Id,
                Title: docLink.ContentDocument?.Title,
                FileType: docLink.ContentDocument?.FileType,
                downloadUrl: `/sfc/servlet.shepherd/document/download/${docLink.ContentDocument?.LatestPublishedVersionId}`
            }));
            this.quoteDocumentsError = undefined;
            console.log('Fetched quote documents:', this.quoteDocuments);
        }
    }
}