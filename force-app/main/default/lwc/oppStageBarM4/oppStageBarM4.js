import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import RECORD_TYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';

const OPPORTUNITY_FIELDS = [STAGE_FIELD, RECORD_TYPE_FIELD];
const MASTER_RECORD_TYPE_ID = '012000000000000AAA';
const COMPLETE_PROGRESS = 100;
const INITIAL_PROGRESS = 0;

export default class OppStageBarM4 extends LightningElement {
    @api recordId;

    objectInfo;
    opportunity;
    picklistValues;
    objectInfoError;
    opportunityError;
    picklistError;

    cardTitle = 'Opportunity Stage';
    progressVariant = 'base';

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    wiredObjectInfo({ data, error }) {
        this.objectInfo = data;
        this.objectInfoError = error;
    }

    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity({ data, error }) {
        this.opportunity = data;
        this.opportunityError = error;
    }

    @wire(getPicklistValues, { recordTypeId: '$effectiveRecordTypeId', fieldApiName: STAGE_FIELD })
    wiredPicklistValues({ data, error }) {
        this.picklistValues = data;
        this.picklistError = error;
    }

    get effectiveRecordTypeId() {
        const recordTypeId = getFieldValue(this.opportunity, RECORD_TYPE_FIELD);
        const defaultRecordTypeId = this.objectInfo?.defaultRecordTypeId;
        return recordTypeId || defaultRecordTypeId || MASTER_RECORD_TYPE_ID;
    }

    get currentStageValue() {
        return getFieldValue(this.opportunity, STAGE_FIELD);
    }

    get currentStageLabel() {
        const matchingStage = this.stages.find((stage) => stage.value === this.currentStageValue);
        return matchingStage?.label || this.currentStageValue || 'Not available';
    }

    get stages() {
        return this.picklistValues?.values || [];
    }

    get currentStageIndex() {
        return this.stages.findIndex((stage) => stage.value === this.currentStageValue);
    }

    get stageCount() {
        return this.stages.length;
    }

    get completedStageCount() {
        if (this.currentStageIndex < 0) {
            return INITIAL_PROGRESS;
        }
        return this.currentStageIndex + 1;
    }

    get progressValue() {
        if (this.stageCount === 0 || this.currentStageIndex < 0) {
            return INITIAL_PROGRESS;
        }
        return Math.round((this.completedStageCount / this.stageCount) * COMPLETE_PROGRESS);
    }

    get progressLabel() {
        return `${this.progressValue}%`;
    }

    get assistiveSummary() {
        if (this.stageCount === 0) {
            return 'Stage progress is not available.';
        }
        return `${this.currentStageLabel} is stage ${this.completedStageCount} of ${this.stageCount}.`;
    }

    get stageSteps() {
        return this.stages.map((stage, index) => {
            const isCurrent = index === this.currentStageIndex;
            const isComplete = index <= this.currentStageIndex;
            return {
                value: stage.value,
                label: stage.label,
                className: this.getStageClass(isCurrent, isComplete),
                ariaCurrent: isCurrent ? 'step' : null
            };
        });
    }

    get showStageList() {
        return this.stageSteps.length > 0;
    }

    get isLoading() {
        return !this.hasError && (!this.opportunity || !this.picklistValues);
    }

    get hasError() {
        return Boolean(this.objectInfoError || this.opportunityError || this.picklistError);
    }

    get errorMessage() {
        const error = this.objectInfoError || this.opportunityError || this.picklistError;
        return this.reduceError(error) || 'Unable to load opportunity stage progress.';
    }

    getStageClass(isCurrent, isComplete) {
        if (isCurrent) {
            return 'stage-item stage-item_current';
        }
        if (isComplete) {
            return 'stage-item stage-item_complete';
        }
        return 'stage-item';
    }

    reduceError(error) {
        if (!error) {
            return '';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        if (typeof error.body?.message === 'string') {
            return error.body.message;
        }
        if (typeof error.message === 'string') {
            return error.message;
        }
        return '';
    }
}
