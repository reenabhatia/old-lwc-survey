@isTest
public with sharing class Schedule_Batch_DRMTest {
	@isTest
	public static void testschedule(){
		Test.startTest();
		Schedule_Batch_DRM sh = new Schedule_Batch_DRM();
		String sch = '0 0 23 * * ?'; 
		system.schedule('Test Batch DRM', sch, sh);
		Test.stopTest();
	}

}