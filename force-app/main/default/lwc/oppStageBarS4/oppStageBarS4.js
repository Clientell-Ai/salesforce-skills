import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';

const OPPORTUNITY_FIELDS = [STAGE_NAME_FIELD];

export default class OppStageBarS4 extends LightningElement {
    @api recordId;

    stageOptions = [];
    currentStageValue;
    picklistError;
    recordError;
    isRecordLoaded = false;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: STAGE_NAME_FIELD
    })
    wiredStagePicklist({ data, error }) {
        this.picklistError = error;
        if (data) {
            this.stageOptions = data.values.map((stage) => ({
                label: stage.label,
                value: stage.value
            }));
            this.picklistError = undefined;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity({ data, error }) {
        this.isRecordLoaded = true;
        this.recordError = error;
        if (data) {
            this.currentStageValue = getFieldValue(data, STAGE_NAME_FIELD);
            this.recordError = undefined;
        }
    }

    get recordTypeId() {
        return this.objectInfo?.data?.defaultRecordTypeId;
    }

    get hasRecordId() {
        return Boolean(this.recordId);
    }

    get isLoading() {
        return this.hasRecordId && (!this.isRecordLoaded || this.stageOptions.length === 0) && !this.hasError;
    }

    get hasError() {
        return Boolean(this.objectInfo?.error || this.picklistError || this.recordError);
    }

    get hasStageData() {
        return this.hasRecordId && this.stageOptions.length > 0 && Boolean(this.currentStageValue) && !this.hasError;
    }

    get currentStageIndex() {
        return this.stageOptions.findIndex((stage) => stage.value === this.currentStageValue);
    }

    get currentStageLabel() {
        const currentStage = this.stageOptions.find((stage) => stage.value === this.currentStageValue);
        return currentStage?.label || this.currentStageValue || 'Unknown';
    }

    get progressValue() {
        if (this.stageOptions.length <= 1 || this.currentStageIndex < 0) {
            return 0;
        }

        return Math.round((this.currentStageIndex / (this.stageOptions.length - 1)) * 100);
    }

    get progressLabel() {
        return `${this.progressValue}%`;
    }

    get progressAriaLabel() {
        return `Opportunity stage progress is ${this.progressLabel}. Current stage is ${this.currentStageLabel}.`;
    }

    get statusMessage() {
        if (this.hasError) {
            return 'Unable to load the Opportunity stage. Verify record access and field permissions.';
        }

        return 'No Opportunity stage is available for this record.';
    }

    get stageItems() {
        return this.stageOptions.map((stage, index) => {
            const isCompleted = index < this.currentStageIndex;
            const isCurrent = index === this.currentStageIndex;
            const stateClass = this.getStageStateClass(isCompleted, isCurrent);
            const stateLabel = this.getStageStateLabel(isCompleted, isCurrent);

            return {
                ...stage,
                className: `stage-item ${stateClass}`,
                ariaCurrent: isCurrent ? 'step' : undefined,
                assistiveText: `${stage.label}: ${stateLabel}`
            };
        });
    }

    getStageStateClass(isCompleted, isCurrent) {
        if (isCurrent) {
            return 'stage-item_current';
        }

        if (isCompleted) {
            return 'stage-item_complete';
        }

        return 'stage-item_pending';
    }

    getStageStateLabel(isCompleted, isCurrent) {
        if (isCurrent) {
            return 'Current stage';
        }

        if (isCompleted) {
            return 'Completed stage';
        }

        return 'Upcoming stage';
    }
}
