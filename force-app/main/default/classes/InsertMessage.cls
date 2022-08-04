@RestResource(UrlMapping='/InsertMessage/*')
global class InsertMessage {
    
    @HttpPost
    global static boolean doPost() {
        try {
            RestRequest restReq = RestContext.request;
            MessageWrapper msgWrapper = (MessageWrapper) JSON.deserialize(restReq.requestBody.toString(), MessageWrapper.class);
            
            Id uid = [
                SELECT Id
                FROM UserId__c
                WHERE Name =: msgWrapper.UserId
                Limit 1
            ].Id;
            
            insertMessage(msgWrapper.message, uid);
            insertPrefixesSuffixes(msgWrapper.message, uid);
            
            return true;
        } catch(Exception e) {
            return false;
        }
    }
    
    private static void insertMessage(String message, Id userID) {
        Integer wrds = message.split(' ').size();
        
        Message__c msg = new Message__c(UserId__c = userID, Body__c = message, Words__c = wrds);
        insert msg;
        
        List<Message__c> messages = [
            SELECT Words__c
            FROM Message__c
            WHERE UserId__c =: userID
        ];
        
        meanMedianMode(userID, messages);
    }
    
    private static void meanMedianMode(Id recordId, List<Message__c> messages) {
        Decimal total = 0;
        List<Decimal> wrds = new List<Decimal>();
        Map<Double, Integer> modeMap = new Map<Double, Integer>();
        for(Message__c msg : messages) {
            total += msg.Words__c;
            wrds.add(msg.Words__c);
            if(modeMap.containsKey(msg.Words__c)) {
                modeMap.put(msg.Words__c,  modeMap.get(msg.Words__c) + 1);
            } else {
                modeMap.put(msg.Words__c, 1);
            }
        }
        total = total / messages.size();
        wrds.sort();
        Integer medn = messages.size() < 3 ? wrds[0].intValue() : wrds[Math.floor(wrds.size() / 2).intValue()].intValue();
        Double currMode = 0;
        Double currModeVal = -99999;
        for(Double key : modeMap.keySet()) {        
            if(modeMap.get(key) > currModeVal) {
                currModeVal = modeMap.get(key);
                currMode = key;
            }
        }
        UserId__c uid = new UserId__c(
            Id = recordId,
            Mean_Words__c = Math.round(total),
            Median_Words__c = medn,
            Mode_Words__c = currMode.intValue()
        );
        
        update uid;
    }
    
    private static void insertPrefixesSuffixes(String message, Id userID) {
        List<String> words = message.split(' ');
        List<Prefix__c> prefixes = new List<Prefix__c>();
        List<Prefix__c> existingPrefixes = [
            SELECT Id, Name
            FROM Prefix__c
            WHERE UserId__c =: userId
        ];
        
        Map<String, String> suffixesToUpdate = new Map<String, String>();
        
        List<Suffix__c> suffixes = new List<Suffix__c>();
        for(Integer i = 0; i < words.size()-2; ++i) {
            String prefix = words.get(i) + ' ' + words.get(i+1);
            String suffix = words.get(i+2);
            Prefix__c existingPrefix = prefixContains(existingPrefixes, prefix);
            if(existingPrefix == null) {
                Prefix__c addingPrefix = prefixContains(prefixes, prefix);
                if(addingPrefix == null) {
                    prefixes.add(new Prefix__c(Name = prefix, UserId__c = userId));
                }
                suffixesToUpdate.put(prefix, suffix);
            } else {
                suffixes.add(new Suffix__c(Name = suffix, Prefix__c = existingPrefix.Id));
            }
        }
        
        insert prefixes;
        
        System.debug(suffixesToUpdate.toString());
        
        for(String prefix : suffixesToUpdate.keySet()) {
            Prefix__c aPrefix = prefixContains(prefixes, prefix);
            System.debug(aPrefix);
            suffixes.add(new Suffix__c(Name = suffixesToUpdate.get(prefix), Prefix__c = aPrefix.Id));
        }
        
        insert suffixes;
    }
    
    private static Prefix__c prefixContains(List<Prefix__c> prefixes, String str) {
        for(Prefix__c p : prefixes) {
            if(p.Name == str) {
                return p;
            }
        }
        
        return null;
    }
    
    private class MessageWrapper {
        public String message;
        public String UserId;
    }
    
    private class getWrapper {
        
    }
}