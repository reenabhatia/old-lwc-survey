global with sharing class SBUX_B2B_cc_hk_SSO extends ccrz.cc_hk_SSO
{
    global virtual override Map<String,Object> getLinkOverrideMap(Map<String,Object> inputData)
    {
        Map<String, Object> outputData = super.getLinkOverrideMap(inputData);
       
        //Using a custom label here in the event we need to use it in lwc
        outputData.put(ccrz.cc_hk_SSO.MYACCOUNT_CHANGEPASSWORD, Label.SSO_Link_ChangePassword_Starbucks_B2B);
        
        return outputData;
    }
}