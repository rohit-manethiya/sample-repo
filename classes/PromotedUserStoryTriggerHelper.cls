public without sharing class PromotedUserStoryTriggerHelper{

    public static String ns {
        get {
            if (null == ns) {
                ns = Settings.ns;
            }
            return ns;
        }
        set;
    }

    public static void prepareCheckBackPromotion(SObject pNew, SObject pOld){
        
    }
}