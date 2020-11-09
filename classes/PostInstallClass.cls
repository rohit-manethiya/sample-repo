/**
 * TODO: If all Copado customers have vesion 10 or above, updatePersonalSettingsAPIKey()
 * and all its references could be removed.
 * The post install script is invoked after tests have been run, and is subject to default governor limits.
 * It runs as a special system user that represents your package, so all operations performed by the script appear to be done by your package.
 * You can access this user by using UserInfo. You will only see this user at runtime, not while running tests.
 * The post install script has the following additional properties.
    -It can initiate batch, scheduled, and future jobs.
    -It can’t access Session IDs.
    -It can only perform callouts using an async operation. The callout occurs after the script is run and the install is complete and committed.
    -It can’t call another Apex class in the package if that Apex class uses the with sharing keyword.
    -This keyword can prevent the package from successfully installing. See the Apex Developer Guide to learn more.
 * */
global class PostInstallClass implements InstallHandler {
    private final static Settings__c orgDefaultSetting = Settings__c.getOrgDefaults();

    private final static Blob newCryptoKey {
        get {
            if (newCryptoKey == null && String.isNotBlank(orgDefaultSetting.CryptoKEY__c)) {
                newCryptoKey = EncodingUtil.base64Decode(orgDefaultSetting.CryptoKEY__c);
            }
            return newCryptoKey;
        }
        set;
    }

    /**
     * Needed to decrypt legacy data we need this key so we can encrypt it again
     * using the new crypto key that is generated per Copado org.
     */
    private final static Blob legacyCryptoKey {
        get {
            if (legacyCryptoKey == null) {
                final String metadataDeprecatedCryptoKey = [
                    SELECT Id, DeveloperName, Text_Field__c
                    FROM Copado_Protected_Settiing__mdt
                    WHERE DeveloperName = 'Deprecated_Key'
                    LIMIT 1
                ]
                .Text_Field__c;
                legacyCryptoKey = EncodingUtil.base64Decode(metadataDeprecatedCryptoKey);
            }
            return legacyCryptoKey;
        }
        set;
    }

    global void onInstall(final InstallContext context) {
        // In v15.1 a new feature parameter is released, which is "NumberOfProductionEnvironment", so we need to update that parameter with following line
        if (isInstallation(context)) {
            FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();
        }


        // Every reference should be either in String query or in Sobject casting
        // There cannot be direct usage of PushTopic object since it would cause a package dependancy with streaming API
        if (
            Schema.getGlobalDescribe().containsKey('PushTopic') &&
            Schema.getGlobalDescribe().get('PushTopic').getDescribe().isDeletable() &&
            Schema.getGlobalDescribe().get('PushTopic').getDescribe().isQueryable()
        ) {
            String queryString = 'SELECT Id, Name FROM PushTopic WHERE Name = \'CopadoNotifications\'';
            List<SObject> pushTopics = Database.query(queryString);
            if (!pushTopics.isEmpty()) {
                delete pushTopics;
            }
        }

        setDefaultSettingsVersion(getCurrentVersion());

        // This is needed when upgrading Copado from previous old versions
        // where crypto key was in Copado_Protected_Settiing__mdt (same crypto key for all orgs)
        // instead of Settings__c.CryptoKEY__c (with a different crypto key per Org)
        if (shouldReencryptData(context)) {
            updatePersonalSettingsAPIKey();
        }
    }

    private static Boolean isInstallation(final InstallContext context) {
        return context != null && context.previousVersion() == null;
    }

    private static String getCurrentVersion() {
        final String currentVersion;
        try {
            // WARNING: This method is not supposed to work after API version v45
            // INFO: This method throws System.TypeException when executed outside of managed context
            UserInfo.isCurrentUserLicensed('copado');
            // INFO: This method throws System.ProcedureException when executed outside of managed context, however, this exception is not catchable
            final Version versionInstalled = System.requestVersion();
            final Integer major = versionInstalled.major();
            final Integer minor = versionInstalled.minor() != null ? versionInstalled.minor() : 0;
            final Integer patch = versionInstalled.patch() != null ? versionInstalled.patch() : 0;
            currentVersion = major + '.' + minor + '.' + patch;
        } catch (final System.TypeException e) {
            // Request version is not supported by unit test classes so hard coded version will move the test forward
            if (Test.isRunningTest()) {
                currentVersion = '16.2.0';
            }
        }
        return currentVersion;
    }

    private static void setDefaultSettingsVersion(final String currentVersion) {
        orgDefaultSetting.Current_Copado_Version__c = currentVersion;

        upsert orgDefaultSetting;

        // This is needed from v16.1 onwards since logic was moved to RegisterCopado
        // This also assures that it is an upgrade, since orgDefaultSetting.CryptoKEY__c
        // is never populated in installations yet
        if (String.isNotBlank(orgDefaultSetting.CryptoKEY__c)) {
            RegisterCopado.updatePackageVersion(currentVersion);
        }
    }

    private static Boolean shouldReencryptData(final InstallContext context) {
        // newCryptoKey needs to be checked in case Copado is upgraded before registering the application
        return newCryptoKey != null &&
            context != null &&
            context.previousVersion() != null &&
            context.previousVersion().compareTo(new Version(10, 0)) >= 0;
    }

    private static void updatePersonalSettingsAPIKey() {
        final List<Personal_Settings__c> allPersonalSettings = [SELECT Id, API_Key__c FROM Personal_Settings__c WHERE API_Key__c != null];
        for (Personal_Settings__c personalSetting : allPersonalSettings) {
            if (isAPIKeyEncrypted(personalSetting.API_Key__c)) {
                decryptAPIKeyAndReencryptWithNewCryptoKey(personalSetting);
            } else {
                personalSetting.API_Key__c = getEncryptedAPIKey(personalSetting.API_Key__c);
            }
        }
        try {
            update allPersonalSettings;
        } catch (final Exception e) {
            // Skip silently
            System.debug(e.getMessage());
        }
    }

    private static Boolean isAPIKeyEncrypted(final String APIKey) {
        return APIKey != null && APIKey.length() >= 40;
    }

    private static String getEncryptedAPIKey(final String clearAPIKey) {
        if (String.isBlank(clearAPIKey)) {
            return null;
        }
        final Blob data = Blob.valueOf(clearAPIKey);
        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', newCryptoKey, data));
    }

    private static void decryptAPIKeyAndReencryptWithNewCryptoKey(final Personal_Settings__c personalSetting) {
        try {
            final Blob encryptedAPIKey = EncodingUtil.base64Decode(personalSetting.API_Key__c);
            final String decryptedAPIKey = Crypto.decryptWithManagedIV('AES256', legacyCryptoKey, encryptedAPIKey).toString();
            personalSetting.API_Key__c = getEncryptedAPIKey(decryptedAPIKey);
        } catch (final Exception e) {
            if (isAPIKeyAlreadyEncryptedWithNewCryptoKey(e)) {
                // Skip silently
                System.debug('Personal_Settings__c decrypt - encrypt exception: ' + e.getMessage());
            } else {
                // Other exceptions may be thrown, for example:
                // System.InvalidParameterValueException: Invalid private key. Must be 32 bytes.
                throw e;
            }
        }
    }

    private static Boolean isAPIKeyAlreadyEncryptedWithNewCryptoKey(final Exception e) {
        return e.getTypeName() == 'System.SecurityException' && e.getMessage() == 'pad block corrupted';
    }
}