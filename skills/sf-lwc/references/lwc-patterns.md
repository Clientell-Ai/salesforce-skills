# LWC Patterns Reference

## 1. Lightning Data Service (LDS) — Wire Adapters

### getRecord with Field Imports

```javascript
import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import OWNER_NAME_FIELD from '@salesforce/schema/Account.Owner.Name';

const FIELDS = [NAME_FIELD, INDUSTRY_FIELD, OWNER_NAME_FIELD];

export default class AccountDetail extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get name() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }

    get industry() {
        return getFieldDisplayValue(this.account.data, INDUSTRY_FIELD);
    }

    get ownerName() {
        return getFieldValue(this.account.data, OWNER_NAME_FIELD);
    }

    get error() {
        return this.account.error;
    }
}
```

**Using optionalFields** (no error if field is inaccessible):

```javascript
@wire(getRecord, {
    recordId: '$recordId',
    fields: [NAME_FIELD],
    optionalFields: [OWNER_NAME_FIELD]
})
account;
```

### getObjectInfo for Object Metadata

```javascript
import { LightningElement, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

export default class ObjectMetadata extends LightningElement {
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    get defaultRecordTypeId() {
        if (this.objectInfo.data) {
            return this.objectInfo.data.defaultRecordTypeId;
        }
        return null;
    }

    get fieldMap() {
        if (this.objectInfo.data) {
            return this.objectInfo.data.fields;
        }
        return {};
    }
}
```

### getPicklistValues and getPicklistValuesByRecordType

```javascript
import { LightningElement, wire, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';

export default class PicklistExample extends LightningElement {
    @api recordId;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    // Single field picklist values
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: INDUSTRY_FIELD
    })
    industryOptions;

    // All picklist values for a record type
    @wire(getPicklistValuesByRecordType, {
        objectApiName: ACCOUNT_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    allPicklistValues;

    get industryPicklistValues() {
        if (this.industryOptions.data) {
            return this.industryOptions.data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        }
        return [];
    }
}
```

### refreshApex() Cache Invalidation

```javascript
import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getContacts from '@salesforce/apex/ContactController.getContacts';

export default class ContactList extends LightningElement {
    @api recordId;

    // Store the full wire result for refreshApex
    wiredContactsResult;

    @wire(getContacts, { accountId: '$recordId' })
    wiredContacts(result) {
        this.wiredContactsResult = result; // cache the provisioned value
        const { data, error } = result;
        if (data) {
            this.contacts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = [];
        }
    }

    async handleRefresh() {
        await refreshApex(this.wiredContactsResult);
    }
}
```

---

## 2. LDS — Imperative Operations

### createRecord

```javascript
import { LightningElement } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/Contact.LastName';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import ACCOUNT_FIELD from '@salesforce/schema/Contact.AccountId';

export default class CreateContact extends LightningElement {
    async handleCreate() {
        const fields = {};
        fields[FIRST_NAME_FIELD.fieldApiName] = 'John';
        fields[LAST_NAME_FIELD.fieldApiName] = 'Doe';
        fields[EMAIL_FIELD.fieldApiName] = 'john.doe@example.com';
        fields[ACCOUNT_FIELD.fieldApiName] = this.accountId;

        try {
            const record = await createRecord({
                apiName: CONTACT_OBJECT.objectApiName,
                fields
            });
            this.contactId = record.id;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Contact created: ' + record.id,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }
}
```

### updateRecord

```javascript
import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/Contact.Id';
import LAST_NAME_FIELD from '@salesforce/schema/Contact.LastName';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';

export default class UpdateContact extends LightningElement {
    @api recordId;

    async handleUpdate() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[LAST_NAME_FIELD.fieldApiName] = 'Smith';
        fields[EMAIL_FIELD.fieldApiName] = 'smith@example.com';

        try {
            await updateRecord({ fields });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Contact updated',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }
}
```

### deleteRecord

```javascript
import { LightningElement, api } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DeleteContact extends LightningElement {
    @api recordId;

    async handleDelete() {
        try {
            await deleteRecord(this.recordId);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record deleted',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }
}
```

---

## 3. Navigation Service

### NavigationMixin.Navigate()

```javascript
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NavigationExample extends NavigationMixin(LightningElement) {
    @api recordId;

    // --- standard__recordPage ---

    navigateToRecordView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    navigateToRecordEdit() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'edit'
            }
        });
    }

    navigateToRecordClone() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'clone'
            }
        });
    }

    // --- standard__objectPage ---

    navigateToObjectHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'home'
            }
        });
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    navigateToNewRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                // Pre-fill field values
                defaultFieldValues: 'Name=Acme,Industry=Technology'
            }
        });
    }

    // --- standard__namedPage ---

    navigateToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }

    navigateToChatter() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'chatter'
            }
        });
    }

    navigateToToday() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'today'
            }
        });
    }

    // --- standard__webPage ---

    navigateToExternalUrl() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://www.example.com'
            }
        });
    }
}
```

### NavigationMixin.GenerateUrl()

```javascript
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class UrlGenerator extends NavigationMixin(LightningElement) {
    @api recordId;
    recordUrl;

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordUrl = url;
        });
    }
}
```

---

## 4. Lightning Message Service (LMS)

### Message Channel Definition XML

File: `force-app/main/default/messageChannels/SampleMessageChannel.messageChannel-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningMessageChannel xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>SampleMessageChannel</masterLabel>
    <isExposed>true</isExposed>
    <description>Channel for cross-component communication</description>
    <lightningMessageFields>
        <fieldName>recordId</fieldName>
        <description>The record Id</description>
    </lightningMessageFields>
    <lightningMessageFields>
        <fieldName>recordData</fieldName>
        <description>The record data payload</description>
    </lightningMessageFields>
</LightningMessageChannel>
```

### Publishing Messages

```javascript
import { LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import SAMPLE_CHANNEL from '@salesforce/messageChannel/SampleMessageChannel__c';

export default class PublisherComponent extends LightningElement {
    @wire(MessageContext)
    messageContext;

    handlePublish() {
        const payload = {
            recordId: '001xx000003ABCDEF',
            recordData: { name: 'Acme Corp', industry: 'Technology' }
        };
        publish(this.messageContext, SAMPLE_CHANNEL, payload);
    }
}
```

### Subscribing with APPLICATION_SCOPE

```javascript
import { LightningElement, wire } from 'lwc';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import SAMPLE_CHANNEL from '@salesforce/messageChannel/SampleMessageChannel__c';

export default class SubscriberComponent extends LightningElement {
    subscription = null;
    receivedRecordId;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                SAMPLE_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleMessage(message) {
        this.receivedRecordId = message.recordId;
        console.log('Received:', JSON.stringify(message.recordData));
    }

    disconnectedCallback() {
        this.unsubscribeFromMessageChannel();
    }

    unsubscribeFromMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
}
```

---

## 5. Lightning Datatable

### Column Definitions and Full Setup

```html
<template>
    <lightning-datatable
        key-field="Id"
        data={data}
        columns={columns}
        sorted-by={sortedBy}
        sorted-direction={sortedDirection}
        onsort={handleSort}
        onrowselection={handleRowSelection}
        onrowaction={handleRowAction}
        oncellchange={handleCellChange}
        draft-values={draftValues}
        show-row-number-column
        hide-checkbox-column={hideCheckbox}
        max-row-selection={maxRowSelection}
    ></lightning-datatable>
</template>
```

```javascript
import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

const ACTIONS = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete', iconName: 'utility:delete' }
];

const COLUMNS = [
    { label: 'Name', fieldName: 'Name', type: 'text', sortable: true, editable: true },
    { label: 'Website', fieldName: 'Website', type: 'url',
        typeAttributes: {
            label: { fieldName: 'Website' },
            target: '_blank'
        }
    },
    { label: 'Phone', fieldName: 'Phone', type: 'phone', editable: true },
    { label: 'Email', fieldName: 'Email__c', type: 'email' },
    { label: 'Revenue', fieldName: 'AnnualRevenue', type: 'currency',
        typeAttributes: { currencyCode: 'USD' },
        sortable: true,
        cellAttributes: { alignment: 'left' }
    },
    { label: 'Created', fieldName: 'CreatedDate', type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    { label: 'Active', fieldName: 'Active__c', type: 'boolean' },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

export default class AccountDatatable extends LightningElement {
    columns = COLUMNS;
    data = [];
    draftValues = [];
    sortedBy;
    sortedDirection = 'asc';

    @wire(getAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.data = data;
        } else if (error) {
            console.error(error);
        }
    }

    // --- Sorting ---
    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;

        const clonedData = [...this.data];
        clonedData.sort((a, b) => {
            let valA = a[fieldName] || '';
            let valB = b[fieldName] || '';
            if (typeof valA === 'string') {
                valA = valA.toLowerCase();
                valB = valB.toLowerCase();
            }
            let result = valA > valB ? 1 : valA < valB ? -1 : 0;
            return sortDirection === 'asc' ? result : -result;
        });
        this.data = clonedData;
    }

    // --- Inline Edit ---
    handleCellChange(event) {
        this.draftValues = event.detail.draftValues;
    }

    async handleSave() {
        // Process this.draftValues to save records
        // Each draft value has the record Id and changed fields
        this.draftValues = [];
    }

    // --- Row Actions ---
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'view':
                this.navigateToRecord(row.Id);
                break;
            case 'edit':
                this.editRecord(row.Id);
                break;
            case 'delete':
                this.deleteRecord(row.Id);
                break;
            default:
                break;
        }
    }

    // --- Row Selection ---
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('Selected:', selectedRows.length, 'rows');
    }
}
```

### Custom Column Type

```javascript
// customDatatable.js
import LightningDatatable from 'lightning/datatable';
import progressTemplate from './progressTemplate.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        progress: {
            template: progressTemplate,
            typeAttributes: ['value', 'variant']
        }
    };
}
```

```html
<!-- progressTemplate.html -->
<template>
    <lightning-progress-bar value={typeAttributes.value} variant={typeAttributes.variant}>
    </lightning-progress-bar>
</template>
```

---

## 6. Custom Events

### Creating CustomEvent with Detail

```javascript
// childComponent.js
import { LightningElement } from 'lwc';

export default class ChildComponent extends LightningElement {
    handleClick() {
        // Simple event
        this.dispatchEvent(new CustomEvent('selected'));

        // Event with data payload
        this.dispatchEvent(new CustomEvent('itemselected', {
            detail: {
                recordId: '001xx000003ABCDEF',
                name: 'Acme Corp'
            }
        }));
    }
}
```

### bubbles + composed for Crossing Shadow Boundary

```javascript
// deepChild.js — event crosses multiple shadow DOM boundaries
this.dispatchEvent(new CustomEvent('globalnotify', {
    detail: { message: 'Something happened deep in the tree' },
    bubbles: true,    // propagates up through the DOM
    composed: true    // crosses shadow DOM boundaries
}));
```

### Parent Listener in Template

```html
<!-- parentComponent.html -->
<template>
    <!-- Event name in template uses "on" prefix, all lowercase -->
    <c-child-component
        onselected={handleSelected}
        onitemselected={handleItemSelected}
    ></c-child-component>
</template>
```

```javascript
// parentComponent.js
import { LightningElement } from 'lwc';

export default class ParentComponent extends LightningElement {
    handleSelected() {
        console.log('Child was selected');
    }

    handleItemSelected(event) {
        const { recordId, name } = event.detail;
        console.log('Selected record:', recordId, name);
    }
}
```

### Stopping Propagation

```javascript
handleEvent(event) {
    event.stopPropagation(); // prevents further bubbling

    // Or prevent default browser behavior
    event.preventDefault();
}
```

---

## 7. Record Forms Comparison

### lightning-record-form (Simplest, Auto Layout)

```html
<template>
    <lightning-record-form
        record-id={recordId}
        object-api-name="Account"
        fields={fields}
        mode="view"
        columns="2"
        onsuccess={handleSuccess}
        onsubmit={handleSubmit}
        onerror={handleError}
    ></lightning-record-form>
</template>
```

```javascript
import { LightningElement, api } from 'lwc';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';

export default class RecordFormExample extends LightningElement {
    @api recordId;
    fields = [NAME_FIELD, INDUSTRY_FIELD, PHONE_FIELD];

    handleSuccess(event) {
        console.log('Record saved:', event.detail.id);
    }

    handleSubmit(event) {
        // Modify fields before submission
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Industry = 'Technology';
        this.template.querySelector('lightning-record-form').submit(fields);
    }
}
```

### lightning-record-edit-form (Custom Layout, Field-Level Control)

```html
<template>
    <lightning-record-edit-form
        record-id={recordId}
        object-api-name="Account"
        onsuccess={handleSuccess}
        onerror={handleError}
    >
        <lightning-messages></lightning-messages>

        <div class="slds-grid slds-gutters">
            <div class="slds-col">
                <lightning-input-field field-name="Name" required></lightning-input-field>
            </div>
            <div class="slds-col">
                <lightning-input-field field-name="Industry"></lightning-input-field>
            </div>
        </div>

        <lightning-input-field
            field-name="Description"
            variant="label-hidden"
        ></lightning-input-field>

        <div class="slds-m-top_medium">
            <lightning-button type="submit" variant="brand" label="Save"></lightning-button>
            <lightning-button label="Cancel" onclick={handleCancel}></lightning-button>
        </div>
    </lightning-record-edit-form>
</template>
```

### lightning-record-view-form (Read-Only Display)

```html
<template>
    <lightning-record-view-form record-id={recordId} object-api-name="Account">
        <div class="slds-grid slds-gutters">
            <div class="slds-col">
                <lightning-output-field field-name="Name"></lightning-output-field>
                <lightning-output-field field-name="Industry"></lightning-output-field>
            </div>
            <div class="slds-col">
                <lightning-output-field field-name="Phone"></lightning-output-field>
                <lightning-output-field field-name="Website"></lightning-output-field>
            </div>
        </div>
    </lightning-record-view-form>
</template>
```

### When to Use Each

| Feature | record-form | record-edit-form | record-view-form |
|---|---|---|---|
| Auto layout | Yes | No (custom) | No (custom) |
| Create mode | Yes | Yes | No |
| Edit mode | Yes | Yes | No |
| View mode | Yes | No | Yes |
| Field-level control | No | Yes | Yes |
| Custom validation | Limited | Yes | N/A |
| Pre-fill values | Yes (onsubmit) | Yes (value attr) | N/A |
| Best for | Quick forms | Complex forms | Display data |

---

## 8. Slot Composition

### Default Slot

```html
<!-- container.html -->
<template>
    <div class="wrapper">
        <slot></slot>
    </div>
</template>
```

```html
<!-- parent.html -->
<template>
    <c-container>
        <p>This goes into the default slot</p>
    </c-container>
</template>
```

### Named Slots

```html
<!-- card.html -->
<template>
    <article class="card">
        <header>
            <slot name="header"></slot>
        </header>
        <div class="body">
            <slot></slot>
        </div>
        <footer>
            <slot name="footer"></slot>
        </footer>
    </article>
</template>
```

```html
<!-- parent.html -->
<template>
    <c-card>
        <h2 slot="header">Card Title</h2>
        <p>This goes in the default (body) slot</p>
        <div slot="footer">
            <lightning-button label="Action" variant="brand"></lightning-button>
        </div>
    </c-card>
</template>
```

### Slot Fallback Content

```html
<!-- component.html -->
<template>
    <div class="container">
        <slot name="icon">
            <!-- Fallback: shown only when no content is provided for this slot -->
            <lightning-icon icon-name="utility:info" size="small"></lightning-icon>
        </slot>
        <slot>
            <p>No content provided.</p>
        </slot>
    </div>
</template>
```

---

## 9. Accessibility (ARIA)

### aria-label, aria-labelledby, aria-describedby

```html
<template>
    <!-- aria-label: direct text label (when no visible label) -->
    <lightning-button
        icon-name="utility:close"
        aria-label="Close dialog"
        onclick={handleClose}
    ></lightning-button>

    <!-- aria-labelledby: reference another element as label -->
    <h2 id="section-heading">Account Details</h2>
    <div aria-labelledby="section-heading" role="region">
        <p>Content here</p>
    </div>

    <!-- aria-describedby: extra description -->
    <lightning-input
        label="Email"
        aria-describedby="email-help"
    ></lightning-input>
    <div id="email-help" class="slds-form-element__help">
        Enter your corporate email address
    </div>
</template>
```

### Role Attributes

```html
<template>
    <div role="alert" if:true={errorMessage}>
        <p>{errorMessage}</p>
    </div>

    <nav role="navigation" aria-label="Main navigation">
        <ul role="menubar">
            <li role="menuitem">
                <a href="#">Home</a>
            </li>
        </ul>
    </nav>

    <div role="status" aria-live="polite">
        {statusMessage}
    </div>
</template>
```

### Keyboard Navigation with tabindex

```html
<template>
    <div
        role="button"
        tabindex="0"
        onclick={handleClick}
        onkeydown={handleKeyDown}
        aria-label="Custom interactive element"
    >
        Click or press Enter
    </div>
</template>
```

```javascript
handleKeyDown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        this.handleClick();
    }
}
```

### Light DOM for Cross-Component ARIA References

```javascript
// lightDomComponent.js
import { LightningElement } from 'lwc';

export default class LightDomComponent extends LightningElement {
    static renderMode = 'light'; // enables light DOM
}
```

```html
<!-- lightDomComponent.html -->
<template>
    <!-- IDs are accessible across components in light DOM -->
    <label id="shared-label">Field Label</label>
</template>
```

---

## 10. SLDS Design Tokens & Styling Hooks

### Using slds-* Utility Classes

```html
<template>
    <div class="slds-p-around_medium slds-m-bottom_small">
        <div class="slds-grid slds-gutters slds-wrap">
            <div class="slds-col slds-size_1-of-2 slds-medium-size_1-of-3">
                <div class="slds-box slds-theme_shade">
                    <p class="slds-text-heading_small slds-truncate">Title</p>
                    <p class="slds-text-body_regular slds-text-color_weak">Subtitle</p>
                </div>
            </div>
        </div>
    </div>
</template>
```

### CSS Custom Properties (Styling Hooks)

```css
/* component.css */

/* Override styling hooks on base components */
c-my-component {
    --slds-c-button-brand-color-background: #4CAF50;
    --slds-c-button-brand-color-background-hover: #45a049;
    --slds-c-button-brand-color-border: #4CAF50;
    --slds-c-input-color-border: #ccc;
    --slds-c-input-radius-border: 8px;
}

/* Use SLDS design tokens via custom properties */
:host {
    --lwc-colorBrand: #4CAF50;
}
```

### :host Selector for Component Root Styling

```css
/* component.css */
:host {
    display: block;
    padding: 1rem;
    border: 1px solid var(--slds-g-color-border-base-1, #e5e5e5);
    border-radius: 0.25rem;
    background-color: var(--slds-g-color-neutral-base-100, #ffffff);
}

:host(.compact) {
    padding: 0.5rem;
}

:host([variant="card"]) {
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
}
```

---

## 11. Third-Party Libraries

### loadScript() and loadStyle()

```javascript
import { LightningElement } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/ChartJs';
import chartCss from '@salesforce/resourceUrl/ChartJsCss';

export default class ChartComponent extends LightningElement {
    chartInitialized = false;

    renderedCallback() {
        if (this.chartInitialized) {
            return;
        }
        this.chartInitialized = true;

        Promise.all([
            loadScript(this, chartJs + '/Chart.min.js'),
            loadStyle(this, chartCss + '/Chart.min.css')
        ])
        .then(() => {
            this.initializeChart();
        })
        .catch((error) => {
            console.error('Error loading Chart.js', error);
        });
    }

    initializeChart() {
        const canvas = this.template.querySelector('canvas.chart');
        const ctx = canvas.getContext('2d');
        this.chart = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['Q1', 'Q2', 'Q3', 'Q4'],
                datasets: [{
                    label: 'Revenue',
                    data: [12, 19, 3, 5]
                }]
            }
        });
    }
}
```

```html
<template>
    <div class="chart-container">
        <canvas class="chart" lwc:dom="manual"></canvas>
    </div>
</template>
```

---

## 12. Dynamic Component Creation

### lwc:component with lwc:is Directive

```html
<template>
    <lwc:component lwc:is={componentConstructor}></lwc:component>
</template>
```

```javascript
import { LightningElement } from 'lwc';

export default class DynamicContainer extends LightningElement {
    componentConstructor;

    async connectedCallback() {
        const { default: ctor } = await import('c/dynamicChild');
        this.componentConstructor = ctor;
    }

    async switchComponent(componentName) {
        // Dynamic import based on component name
        switch (componentName) {
            case 'chart':
                this.componentConstructor = (await import('c/chartComponent')).default;
                break;
            case 'table':
                this.componentConstructor = (await import('c/tableComponent')).default;
                break;
            default:
                this.componentConstructor = (await import('c/defaultComponent')).default;
        }
    }
}
```

### Passing Properties to Dynamic Components

```html
<template>
    <lwc:component
        lwc:is={componentConstructor}
        record-id={recordId}
        oncustomevent={handleEvent}
    ></lwc:component>
</template>
```

---

## 13. Experience Cloud (Communities)

### LWC Targets for Community Pages

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>59.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
        <target>lightningCommunity__Page</target>
        <target>lightningCommunity__Default</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightningCommunity__Default">
            <property name="heading" type="String" label="Heading" default="Welcome" />
            <property name="showImage" type="Boolean" label="Show Image" default="true" />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Guest User Rendering Considerations

```javascript
import { LightningElement, wire } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import Id from '@salesforce/user/Id';

export default class CommunityComponent extends LightningElement {
    get isGuestUser() {
        return isGuest;
    }

    get currentUserId() {
        return Id;
    }
}
```

```html
<template>
    <template if:true={isGuestUser}>
        <div class="guest-content">
            <p>Welcome, guest! Please log in for full access.</p>
            <lightning-button label="Login" onclick={handleLogin}></lightning-button>
        </div>
    </template>
    <template if:false={isGuestUser}>
        <div class="authenticated-content">
            <p>Welcome back!</p>
            <!-- Full authenticated content -->
        </div>
    </template>
</template>
```

### Community-Specific Navigation

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';

export default class CommunityNav extends NavigationMixin(LightningElement) {
    // Navigate to a community page
    navigateToCommunityPage() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Custom_Page__c'
            }
        });
    }

    // Navigate to login page
    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'login'
            }
        });
    }

    // Build a full community URL
    get communityUrl() {
        return `${basePath}/s/custom-page`;
    }

    // Navigate to a record in community context
    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}
```
