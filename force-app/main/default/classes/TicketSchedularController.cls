public with sharing class TicketSchedularController {

    @AuraEnabled(cacheable=true)
    public static List<FX5__Ticket__c> getTicketdata(
        String sortBy,
        String sortDirection,
        String searchName,
        Date searchticktDate,
        String searchLOB,
        String searchDF,
        String searchSW,
        String searchSegment
    ) {
        String searchPattern = '%' + searchName + '%';
        String status1 = 'Void';
        Date todaytoday = Date.today();
        String officeName='WM LIQUID WASTE MANAGEMENT - GMA';

        String query = 'SELECT Id, Name,FX5__Office__c, FX5__Ticket_Date__c, Schedule_Start_Date__c, ' +
                   'Route_Info__r.Name, Route_Info__c, Price_Book_Expired_Indicator__c, ' +
                   'Vehicle__c, Requested_Loads__c, Number_of_Loads__c, Seq__c, Service_Requester__c,Service_Requester_Phone__c,' +
                   'Schedule_Type__c, Schedule_End_Date__c, Weekly__c, Recur_Week__c, Monthly__c, Day__c,' +
                   'of_every_months__c, Recur_Year__c, Job_Status_Indicator__c, LastModifiedBy.Name, LastModifiedDate,' +
                   'Disposal_Facility__c, Service_Address__c, Disposal_Facility__r.Name,Service_Window_Start__c,Service_Window_End__c,' +
                   'LOB__c, Segment__c, Scheduled_Service_Window__c, Ticket_StatusName__c, ' +
                   'Assigned_To__r.Name, Driver_Name__c, FX5__Job__r.Name, ' +
                   'Third_Party_Subcontractor__c, Assigned_To__c, Field_Ticket_Notes__c ' +
                   'FROM FX5__Ticket__c ' +
                   'WHERE Schedule_Start_Date__c != null ' +
                   'AND (Schedule_End_Date__c = null OR Schedule_End_Date__c > :todaytoday) ' +
                   'AND Ticket_StatusName__c != :status1 '+
                   'AND FX5__Office__c=:officeName';

        if (!String.isBlank(searchName)) {
            query += ' AND (Name LIKE :searchPattern ' +
                     'OR Route_Info__r.Name LIKE :searchPattern ' +
                     'OR Assigned_To__r.Name LIKE :searchPattern ' +
                     'OR Ticket_StatusName__c LIKE :searchPattern ' +
                     'OR FX5__Job__r.Name LIKE :searchPattern)';
        }

        if (!String.isBlank(searchLOB)) {
            query += ' AND LOB__c LIKE \'%' + String.escapeSingleQuotes(searchLOB) + '%\'';
        }
        if (!String.isBlank(searchDF)) {
            query += ' AND Disposal_Facility__r.Name LIKE \'%' + String.escapeSingleQuotes(searchDF) + '%\'';
        }
        if (!String.isBlank(searchSW)) {
            query += ' AND Scheduled_Service_Window__c LIKE \'%' + String.escapeSingleQuotes(searchSW) + '%\'';
        }
        if (!String.isBlank(searchSegment)) {
            query += ' AND Segment__c LIKE \'%' + String.escapeSingleQuotes(searchSegment) + '%\'';
        }
        if (searchticktDate != null) {
            query += ' AND FX5__Ticket_Date__c = :searchticktDate';
        }
        if (!String.isBlank(sortBy) && !String.isBlank(sortDirection)) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }

        List<FX5__Ticket__c> ticketList = Database.query(query);
        return ticketList;
    }

   

    @AuraEnabled
    public static List<String> saveticketData(List<Map<String, String>> arrayOfObjects) {
   System.debug('saveticketData: Method called '  );
        // Build status maps
        Map<Id, FX5__Status__c> IdStatusMap = new Map<Id, FX5__Status__c>();
        Map<String, Id> Statusnameidmap = new Map<String, Id>();
        for (FX5__Status__c st : [
            SELECT Id, Name, FX5__SObject__c
            FROM FX5__Status__c
            WHERE FX5__SObject__c = 'Ticket__c'
        ]) {
            IdStatusMap.put(st.Id, st);
            Statusnameidmap.put(st.Name, st.Id);
        }

        // Query tickets for error messages (need Name for user-friendly errors)
        Map<Id, FX5__Ticket__c> ticketQueryMap = new Map<Id, FX5__Ticket__c>([
            SELECT Id, Name, Ticket_StatusName__c
            FROM FX5__Ticket__c
            WHERE Ticket_StatusName__c = 'In Progress'
               OR Ticket_StatusName__c = 'Pending'
        ]);

        // ── FIX 1: Group incoming field changes by recordId ──
        Map<Id, Map<String, String>> uniqueCombinationMap = new Map<Id, Map<String, String>>();
        for (Map<String, String> record : arrayOfObjects) {
            String fieldName = record.get('fieldName');
            Id recordId     = (Id) record.get('recordId');
            String value    = record.get('value');
             System.debug(value);
            if (!uniqueCombinationMap.containsKey(recordId)) {
                uniqueCombinationMap.put(recordId, new Map<String, String>());
            }
            uniqueCombinationMap.get(recordId).put(fieldName, value);
        }

        // ── FIX 2: Build ticket SObjects — handle ALL editable fields ──
        Map<Id, FX5__Ticket__c> ticketMap = new Map<Id, FX5__Ticket__c>();

        for (Id recId : uniqueCombinationMap.keySet()) {
            FX5__Ticket__c ticket = new FX5__Ticket__c(Id = recId);
            Map<String, String> fieldsMap = uniqueCombinationMap.get(recId);

            for (String fieldName : fieldsMap.keySet()) {
                String value = fieldsMap.get(fieldName);
                Boolean isEmpty = String.isBlank(value);

                // ── String fields: set null when blank, value when not ──
                if (fieldName == 'Service_Requester__c') { 
                    ticket.Service_Requester__c = isEmpty ? null : value;
                }
                 else if (fieldName == 'Service_Requester_Phone__c') {
                    ticket.Service_Requester_Phone__c = isEmpty ? null : value;
                }
                else if (fieldName == 'Schedule_Type__c') {
                    ticket.Schedule_Type__c = isEmpty ? null : value;
                }
                else if (fieldName == 'Weekly__c') {
                    ticket.Weekly__c = isEmpty ? null : value;
                }
                else if (fieldName == 'Monthly__c') {
                    ticket.Monthly__c = isEmpty ? null : value;
                }
                else if (fieldName == 'Day__c') {
                    ticket.Day__c = isEmpty ? null : value;
                }
                else if (fieldName == 'Service_Window_Start__c') {
                if(value!=NULL &&  value!=''){
                    String[] strTimeSplit = value.split(':'); Time timeChange = Time.newInstance( Integer.valueOf(strTimeSplit[0]) ,Integer.valueOf(strTimeSplit[1]),0  ,0); ticket.Service_Window_Start__c =  timeChange; 
                   
                                 
           
                                     
                   
                       }
                }
                else if (fieldName == 'Service_Window_End__c') {
                    if(value!=NULL &&  value!=''){
                     String[] strTimeSplit = value.split(':'); Time timeChange = Time.newInstance( Integer.valueOf(strTimeSplit[0])  ,Integer.valueOf(strTimeSplit[1]) ,0  ,0); ticket.Service_Window_End__c = timeChange;
                   
                   
                    }
                }

                // ── Lookup fields: set null when blank, Id when not ──
                else if (fieldName == 'Disposal_Facility__c') {
                       System.debug(fieldName);
                         ticket.Disposal_Facility__c = isEmpty ? null : (Id) value;
                }

                // ── Date fields: parse string → Date ──
                // FIX 3: Was casting Schedule_Type__c as Date — now correctly parses the date string
                else if (fieldName == 'Schedule_Start_Date__c') {
                        ticket.Schedule_Start_Date__c = isEmpty ? null : Date.valueOf(value);
                }
                else if (fieldName == 'Schedule_End_Date__c') {
                    ticket.Schedule_End_Date__c = isEmpty ? null : Date.valueOf(value);
                }

                // ── Numeric fields ──
                else if (fieldName == 'Recur_Week__c') {
                    ticket.Recur_Week__c = isEmpty ? null : Decimal.valueOf(value);
                }
                else if (fieldName == 'of_every_months__c') {
                    ticket.of_every_months__c = isEmpty ? null : Decimal.valueOf(value);
                }
                else if (fieldName == 'Recur_Year__c') {
                    ticket.Recur_Year__c = isEmpty ? null : Decimal.valueOf(value);
                }
            }

            ticketMap.put(recId, ticket);
        }

        System.debug('ticketMap: ' + ticketMap);

        // ── FIX 4: Catch block now returns the error instead of null ──
        try {
           // List<Database.SaveResult> drslist = Database.update(ticketMap.values(), false);
            // Convert map values to a LIST to preserve order
List<FX5__Ticket__c> ticketList = new List<FX5__Ticket__c>(ticketMap.values());

// Perform partial update
List<Database.SaveResult> drslist = Database.update(ticketList, false);
List<String> messagevalue = new List<String>();

for (Integer i = 0; i < drslist.size(); i++) {
    Database.SaveResult drs = drslist[i];

    if (!drs.isSuccess()) {
        // Get the original record using index
        FX5__Ticket__c failedRecord = [Select Id,Name from FX5__Ticket__c WHERE Id=:drs.getId()];
        // Safely get Name
        String ticketName = failedRecord.Name != null  ? failedRecord.Name : 'Record ' + (i + 1);
         System.debug('record Id'+drs.getId());
        for (Database.Error err : drs.getErrors()) {
             System.debug('record Id'+drs.getId());
            messagevalue.add(ticketName + ' : ' + err.getMessage());
        }
    }
}

return messagevalue;

        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            // FIX 4 continued: return the exception message so JS can display it
            return new List<String>{ 'Unexpected error: ' + e.getMessage() };
        }
    }
}