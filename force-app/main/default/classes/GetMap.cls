@RestResource(UrlMapping='/GetMap/*')
global class GetMap {
	@HttpPost
    global static Map<String, List<String>> doGet() {
        RestRequest restReq = RestContext.request;
        inputWrapper inputWrpper = (inputWrapper) JSON.deserialize(restReq.requestBody.toString(), inputWrapper.class);
        Map<String, List<String>> markovMap = new Map<String, List<String>>();
        
        List<Prefix__c> prefixes = [
            SELECT Name, (SELECT Name FROM Suffiexes__r)
            FROM Prefix__c
            WHERE UserId__r.Name =: inputWrpper.userId
        ];
        
        for(Prefix__c prefix : prefixes) {
            List<String> suffixes = new List<String>();
            for(Suffix__c suffix : prefix.Suffiexes__r) {
                suffixes.add(suffix.Name);
            }
            markovMap.put(prefix.Name, suffixes);
        }
        
        return markovMap;
    }
    
    private class inputWrapper {
        public String userId;
    }
}