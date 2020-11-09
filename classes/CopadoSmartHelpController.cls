/**
 * Global smart tips component
 * Marking is global since customers may use this in their own pages as well.
 * Global managed components can be used by end users
 * @see CopadoSmartHelpComponent
 * <pre>
 * {@code <copado:CopadoSmartHelpComponent />}
 * </pre>
 * @version 1.0
 * @author Mert YALTI
 *
 */
global with sharing class CopadoSmartHelpController  {
	@TestVisible private Set<String> removedTips { get; set; } // List of removed tips in order to avoid displaying them again
	global List<SmartHelp> helpList { get; set; } // List of tips to display
	global String tipType { get; set; } // To display correct tip for grid selections. (MetadataType)
	global String tipKey { get; set; } // The apiName for the tip to remove from display list
	global Boolean showTips { get; set; } // Show entire tip panel if there is at least one tip created otherwise hide it
    global Boolean tipsAllowed { get; set; } // If Show_Copado_Tips__c field on user is checked tips will be displayed
    global String vfPageName { 
        get; 
        set {
            vfPageName = vfPageName != null ? vfPageName.replace('copado__', '') : value.replace('copado__', '');
        } 
    } // Current VF page name
    private final String ALWAYS_SHOW = 'Always Show';
    
    
    global copadoSmartHelpController() {
		tipsAllowed = [SELECT Show_Copado_Tips__c FROM User WHERE Id = :UserInfo.getUserId()][0].Show_Copado_Tips__c;
		helpList = new List<SmartHelp>();
		removedTips = new Set<String>();
		showTips = false;
    }
    

	/**
	 * Adds always show type of tips to page when page load is completed
	 * @see SmartHelp
	 * @return PageReference
	 */
	global PageReference setHelpList() {
		if (!tipsAllowed) {
            return null;
        }

		helpList = new List<SmartHelp>();
        
        for (Copado_Smart_Help__mdt csh : getCopadoSmartHelps()) {
            if(csh.Base_Page__c == vfPageName && csh.Triggering_Action__c == ALWAYS_SHOW) {
                SmartHelp sHelp = new smartHelp(csh.DeveloperName, csh.Label, csh.Triggering_Action__c, csh.Triggering_Value__c, csh.Help_Text__c);
                helpList.add(sHelp);
            }
        }
        
		if (!helpList.isEmpty()) {
			showTips = true;
		}
		return null;
    }
    

	/**
	 * To be able to identify tips properly following method converts tips list to tips map
	 * @see SmartHelp
	 * @return Map<String, SmartHelp>
	 */
	private Map<String, SmartHelp> convertHelpListToMap() {
		Map<String, SmartHelp> apiNameToSmartHelpMap = new Map<String, SmartHelp>();
		for (SmartHelp sHelp : helpList) {
			apiNameToSmartHelpMap.put(sHelp.apiName, sHelp);
		}
		return apiNameToSmartHelpMap;
    }
    
	/**
	 * Removes tip from display list
	 * @return PageReference
	 */
	global PageReference removeTip() {
		if (!tipsAllowed || String.isBlank(tipKey)) {
            return null;
        }
        
		Map<String, SmartHelp> apiNameToSmartHelpMap = convertHelpListToMap();
		if (apiNameToSmartHelpMap.containsKey(tipKey)) {
			apiNameToSmartHelpMap.remove(tipKey);
			removedTips.add(tipKey);
			helpList = new List<SmartHelp>();
			helpList.addAll(apiNameToSmartHelpMap.values());
		}
		return null;
    }
    

	/**
	 * Show tips by checking tip type
	 * This method is created particularly for grid selections
	 * @return PageReference
	 */
	global PageReference setTypeList() {
		if(String.isBlank(vfPageName)) {
			vfPageName = ApexPages.currentPage().getParameters().get('pageName');
        }
        
		if(!tipsAllowed || String.isBlank(tipType)) {
            return null;
        }

		Map<String, SmartHelp> apiNameToSmartHelpMap = convertHelpListToMap();
        showTips = false;
        
		for (Copado_Smart_Help__mdt csh : getCopadoSmartHelps()) {
            if(csh.Base_Page__c == vfPageName && csh.Triggering_Action__c != ALWAYS_SHOW && !removedTips.contains(csh.DeveloperName) && csh.Triggering_Value__c == tipType) {
                SmartHelp sh = new smartHelp(csh.DeveloperName, csh.Label, csh.Triggering_Action__c, csh.Triggering_Value__c, csh.Help_Text__c);
                apiNameToSmartHelpMap.put(csh.DeveloperName, sh);
            }
        }
        
		if(!apiNameToSmartHelpMap.keySet().isEmpty()) {
			showTips = true;
			helpList = new List<SmartHelp>();
			helpList.addAll(apiNameToSmartHelpMap.values());
		}
		return null;
    }

    /**
     * General Copado smart help query
     */
    private List<Copado_Smart_Help__mdt> getCopadoSmartHelps() {
        return [SELECT Base_Page__c, DeveloperName, Help_Text__c, Id, Label, Triggering_Action__c, Triggering_Value__c FROM Copado_Smart_Help__mdt ORDER BY Triggering_Value__c LIMIT 1000];
    }
    
    
	/**
	 * Wrapper class for tips
	 */
	global class SmartHelp {
		global String apiName { get; set; }
		global String label { get; set; }
		global String t_action { get; set; }
		global String t_value { get; set; }
		global String helpText { get; set; }

		global smartHelp(String apiName, String label, String t_action, String t_value, String helpText) {
			this.apiName = apiName;
			this.label = label;
			this.t_action = t_action;
			this.t_value = t_value;
			this.helpText = helpText;
		}
	}
}