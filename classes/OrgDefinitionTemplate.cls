public with sharing class OrgDefinitionTemplate implements IDXTemplate {
    public String orgName { get; set; }
    public String country { get; set; }
    public String username { get; set; }
    public String adminEmail { get; set; }
    public String edition { get; set; }
    public String description { get; set; }
    public Boolean hasSampleData { get; set; }
    public String language { get; set; }

    public OrgDefinitionTemplate() {}

    public OrgDefinitionTemplate(String orgName, String country, String username, String adminEmail, String edition, String description, Boolean hasSampleData, String language) {
        this.orgName = orgName;
        this.country = country;
        this.username = username;
        this.adminEmail = adminEmail;
        this.edition = edition;
        this.description = description;
        this.hasSampleData = hasSampleData;
        this.language = language;
    }

    public void create() {

    }

    public IDXTemplate getTemplate() {
        return this;
    }
}