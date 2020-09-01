/**
 * Controller for the ListView buttons on AutoshipHeader object
 *
 *   Qualifies AutoshipHeaderIds, then queues chained BatchJob processing 
 *      [via SBUX_B2B_AutoShipDeleteForecastJob w/ parameters based on desired AutoshipHeader Status]
 */

public class SBUX_B2B_AutoShipGenerateCtrl {
    
    public final List<SBUX_B2B_AutoShipHeader__c> selectedHeaderList;
    public final SBUX_B2B_AutoShipHeader__c singleAutoshipHeader;

    private static final String AUTOSHIP_STATUS_DRAFT = 'Draft';
    private static final String AUTOSHIP_STATUS_FORECAST = 'Forecasted';
    private static final String AUTOSHIP_STATUS_PREVIEW = 'In Preview';
    private static final String AUTOSHIP_STATUS_PROCESS_FORECAST = 'Processing Forecast';
    private static final String AUTOSHIP_STATUS_PROCESS_PREVIEW = 'Processing Preview';
    private static final String AUTOSHIP_STATUS_PROCESS_ORDERS = 'Processing Orders';

    //context for RecordPage
    public SBUX_B2B_AutoShipGenerateCtrl(ApexPages.StandardController stdController) {
        this.singleAutoshipHeader = (SBUX_B2B_AutoShipHeader__c)stdController.getRecord();
    }

    //context for ListView
    public SBUX_B2B_AutoShipGenerateCtrl(ApexPages.StandardSetController stdSetController) {
        this.selectedHeaderList = stdSetController.getSelected();
    }


    // Generate Autoship Forecast data for qualifying AutoshipHeaders (works with & without selected ListView records)
    //    AutoshipHeader.Status must be "Draft","Forecasted",or "In Preview" to qualify
    public void autoShipForecastAll() {
        
        List<SBUX_B2B_AutoShipHeader__c> qualifiedHeaders = new List<SBUX_B2B_AutoShipHeader__c>();
        
        //check if setController found listview selections
        if(selectedHeaderList <> null && selectedHeaderList.size() > 0)
        {
            //create Set of selectHeader ids
            Set<Id> selectedHeaderIds = (new Map<Id,SObject>(selectedHeaderList)).keySet();
            
            //select AutoshipHeader records that are in IdSet AND are qualified
            qualifiedHeaders = [SELECT Id FROM SBUX_B2B_AutoShipHeader__c WHERE Id IN :selectedHeaderIds AND 
                    (SBUX_B2B_AutoshipStatus__c =: AUTOSHIP_STATUS_DRAFT
                    OR SBUX_B2B_AutoshipStatus__c =: AUTOSHIP_STATUS_FORECAST
                    OR SBUX_B2B_AutoshipStatus__c =: AUTOSHIP_STATUS_PREVIEW)];
        }
        else {
            //if no selected headers from ListView, do nothing
        }
        
        //kickoff Delete,+Process jobs for qualified headers
        if (qualifiedHeaders.size()>0)
        {
            for (SBUX_B2B_AutoShipHeader__c header : qualifiedHeaders)
            {
                //call Forecast batch job with autoshipHeaderId, with 'Process' flag to true
                Id batchDeleteId = Database.executeBatch(new SBUX_B2B_AutoShipDeleteForecastJob(header.Id,true,true,false,false), SBUX_B2B_AutoShipUtil.DELETE_FORECAST_BATCH_SIZE);
                
                //update AutoshipHeader status to 'Processing Forecast'
                header.SBUX_B2B_AutoshipStatus__c = AUTOSHIP_STATUS_PROCESS_FORECAST;
                update header;
            }
        } else {
            //no qualified Autoship Headers found!
        }
 
    }
    
    // Generate Autoship Preview data for qualifying AutoshipHeaders (works with & without selected ListView records)
    //    AutoshipHeader.Status must be "Forecasted" or "In Preview" to qualify
    public void autoShipPreviewAll() {
        
        List<SBUX_B2B_AutoShipHeader__c> qualifiedHeaders = new List<SBUX_B2B_AutoShipHeader__c>();
        
        //check if setController found listview selections
        if(selectedHeaderList <> null && selectedHeaderList.size() > 0)
        {
            //create Set of selectHeader ids
            Set<Id> selectedHeaderIds = (new Map<Id,SObject>(selectedHeaderList)).keySet();
            
            //select AutoshipHeader records that are in IdSet AND are qualified
            qualifiedHeaders = [SELECT Id FROM SBUX_B2B_AutoShipHeader__c WHERE Id IN :selectedHeaderIds AND 
                    (SBUX_B2B_AutoshipStatus__c =: AUTOSHIP_STATUS_FORECAST
                    OR SBUX_B2B_AutoshipStatus__c =: AUTOSHIP_STATUS_PREVIEW)];
        }
        else {
            //if no selected headers from ListView, do nothing
        }
        
        //kickoff Delete,Process,+Split jobs for qualified headers
        if (qualifiedHeaders.size()>0)
        {
            for (SBUX_B2B_AutoShipHeader__c header : qualifiedHeaders)
            {
                //call Delete batch job with autoshipHeaderId, with 'Process' and "split" flags set to true
                Id batchDeleteId = Database.executeBatch(new SBUX_B2B_AutoShipDeleteForecastJob(header.Id,true,true,true,false), SBUX_B2B_AutoShipUtil.DELETE_FORECAST_BATCH_SIZE);
                
                //update AutoshipHeader status to 'Processing Preview'
                header.SBUX_B2B_AutoshipStatus__c = AUTOSHIP_STATUS_PROCESS_PREVIEW;
                update header;
            }
        } else {
            //no qualified Autoship Headers found!
        }
 
    }
    
    // Take qualifying CCOrders related to qualified AutoshipHeaders and turns them to Submitted
    //    AutoshipHeader.Status must be "In Preview" to qualify
    public void autoShipSubmitAll() {
        
        List<SBUX_B2B_AutoShipHeader__c> qualifiedHeaders = new List<SBUX_B2B_AutoShipHeader__c>();
        
        //check if setController found listview selections
        if(selectedHeaderList <> null && selectedHeaderList.size() > 0)
        {
            //create Set of selectHeader ids
            Set<Id> selectedHeaderIds = (new Map<Id,SObject>(selectedHeaderList)).keySet();
            
            //select AutoshipHeader records that are in IdSet AND are qualified
            qualifiedHeaders = [SELECT Id FROM SBUX_B2B_AutoShipHeader__c WHERE 
                    Id IN :selectedHeaderIds AND SBUX_B2B_AutoshipStatus__c =: AUTOSHIP_STATUS_PREVIEW ];
        }
        else {
            //if no selected headers from ListView, do nothing
        }
        
        //process submit job for qualified headers
        if (qualifiedHeaders.size()>0)
        {
            for (SBUX_B2B_AutoShipHeader__c header : qualifiedHeaders)
            {
                //call Submit batch job with autoshipHeaderId
                Id batchFinalizeOrdersId = Database.executeBatch(new SBUX_B2B_AutoShipDeleteForecastJob(header.Id,true,true,true,true), SBUX_B2B_AutoShipUtil.DELETE_FORECAST_BATCH_SIZE);
                
                //update AutoshipHeader status to 'Processing Orders' 
                header.SBUX_B2B_AutoshipStatus__c = AUTOSHIP_STATUS_PROCESS_ORDERS;
                update header;
            }
        } else {
            //no qualified Autoship Headers found!
        }
 
    }
 
}