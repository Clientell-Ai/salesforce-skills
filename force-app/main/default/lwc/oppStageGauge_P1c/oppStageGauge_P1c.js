import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';

const OPPORTUNITY_FIELDS = [STAGE_NAME_FIELD];
const FALLBACK_PERCENTAGE = 50;
const UNKNOWN_STAGE_MESSAGE = 'This custom or unknown stage is shown at a neutral midpoint. Update the component mapping to assign a precise percentage.';

const STAGE_PROGRESS = new Map([
    ['Prospecting', 10],
    ['Qualification', 20],
    ['Needs Analysis', 30],
    ['Value Proposition', 40],
    ['Id. Decision Makers', 50],
    ['Perception Analysis', 60],
    ['Proposal/Price Quote', 70],
    ['Negotiation/Review', 80],
    ['Closed Won', 100],
    ['Closed Lost', 0]
]);

export default class OppStageGauge_P1c extends LightningElement {
    @api recordId;

    stageName;
    errorMessage;

    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            this.stageName = getFieldValue(data, STAGE_NAME_FIELD);
            this.errorMessage = undefined;
            return;
        }

        if (error) {
            this.stageName = undefined;
            this.errorMessage = this.reduceError(error);
        }
    }

    get hasStageData() {
        return Boolean(this.stageName);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get progressValue() {
        if (!this.stageName) {
            return 0;
        }

        return STAGE_PROGRESS.has(this.stageName) ? STAGE_PROGRESS.get(this.stageName) : FALLBACK_PERCENTAGE;
    }

    get progressLabel() {
        return `${this.progressValue}%`;
    }

    get isKnownStage() {
        return STAGE_PROGRESS.has(this.stageName);
    }

    get progressVariant() {
        return this.stageName === 'Closed Lost' ? 'circular' : 'base';
    }

    get gaugeStyle() {
        return `--opp-stage-gauge-progress: ${this.progressValue}%;`;
    }

    get meterAriaLabel() {
        return `Opportunity stage ${this.stageName} is ${this.progressValue} percent complete`;
    }

    get helperText() {
        if (this.isKnownStage) {
            return 'Progress is based on a standard ordered Opportunity stage mapping.';
        }

        return UNKNOWN_STAGE_MESSAGE;
    }

    get helperTextClass() {
        return this.isKnownStage
            ? 'slds-text-body_small slds-text-color_weak slds-m-top_medium'
            : 'slds-text-body_small slds-text-color_weak slds-m-top_medium custom-stage-note';
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((entry) => entry.message).join(', ');
        }

        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }

        return 'Unable to load the Opportunity stage.';
    }
}
