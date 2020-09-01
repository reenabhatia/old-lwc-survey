global class Schedule_Batch_DRM implements Schedulable {

   global void execute(Schedulablecontext sc) {
       Batch_DRM_Initiate_Build drm = new Batch_DRM_Initiate_Build();
       Database.executeBatch(drm);
   }
}