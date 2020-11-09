public with sharing class TemplateFactory {
    public IDXTemplate getInstance(String templateType) {
        try {
            if(templateType == 'ProjectJson') {
                return new ProjectTemplate();
            } else if(templateType == 'OrgDefinitionTemplate') {
                return new OrgDefinitionTemplate();
            } else if(templateType == 'OrgExtensionTemplate') {
                return new OrgExtensionTemplate();
            }
        } catch(Exception ex) {
            return null; // TODO: THROW EXCEPTION 
        }
        return null;
    }
}