import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import RECORD_TYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';

const OPPORTUNITY_FIELDS = [STAGE_FIELD, RECORD_TYPE_FIELD];
const ERROR_MESSAGE = 'Unable to load Opportunity stage information.';
const NO_CURRENT_STAGE_INDEX = -1;

export default class OppStageRibbon_GH1 extends LightningElement {
    @api recordId;

    stageName;
    recordTypeId;
    objectInfo;
    picklistValues;
    recordError;
    objectInfoError;
    picklistError;

    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            this.stageName = getFieldValue(data, STAGE_FIELD);
            this.recordTypeId = getFieldValue(data, RECORD_TYPE_FIELD);
            this.recordError = undefined;
            return;
        }

        if (error) {
            this.stageName = undefined;
            this.recordTypeId = undefined;
            this.recordError = error;
        }
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
            this.objectInfoError = undefined;
            return;
        }

        if (error) {
            this.objectInfo = undefined;
            this.objectInfoError = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$effectiveRecordTypeId', fieldApiName: STAGE_FIELD })
    wiredStageValues({ data, error }) {
        if (data) {
            this.picklistValues = data.values;
            this.picklistError = undefined;
            return;
        }

        if (error) {
            this.picklistValues = undefined;
            this.picklistError = error;
        }
    }

    get effectiveRecordTypeId() {
        if (this.recordTypeId) {
            return this.recordTypeId;
        }

        return this.objectInfo?.defaultRecordTypeId;
    }

    get isLoading() {
        return !this.hasError && (!this.recordId || !this.objectInfo || !this.effectiveRecordTypeId || !this.picklistValues);
    }

    get hasError() {
        return Boolean(this.recordError || this.objectInfoError || this.picklistError);
    }

    get errorMessage() {
        return this.extractErrorMessage(this.recordError || this.objectInfoError || this.picklistError);
    }

    get hasStages() {
        return this.stageSteps.length > 0;
    }

    get stageSteps() {
        if (!this.picklistValues) {
            return [];
        }

        const currentStageIndex = this.picklistValues.findIndex((stage) => stage.value === this.stageName);

        return this.picklistValues.map((stage, index) => {
            const isCurrent = index === currentStageIndex;
            const isCompleted = currentStageIndex !== NO_CURRENT_STAGE_INDEX && index < currentStageIndex;
            const stateName = this.getStateName(isCompleted, isCurrent);

            return {
                value: stage.value,
                label: stage.label,
                displayIndex: index + 1,
                isCompleted,
                containerClass: `stage-step stage-step_${stateName}`,
                markerClass: `stage-marker stage-marker_${stateName}`,
                ariaCurrent: isCurrent ? 'step' : null
            };
        });
    }

    getStateName(isCompleted, isCurrent) {
        if (isCompleted) {
            return 'completed';
        }

        if (isCurrent) {
            return 'current';
        }

        return 'upcoming';
    }

    extractErrorMessage(error) {
        if (!error) {
            return ERROR_MESSAGE;
        }

        if (Array.isArray(error.body)) {
            return error.body.map((entry) => entry.message).join(', ');
        }

        return error.body?.message || error.message || ERROR_MESSAGE;
    }
}
