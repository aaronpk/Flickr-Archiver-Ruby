$(function(){

  /**
   * Show closer map on hover
   */
  $(".photo_map").bind("mouseover", function(){
    $("#photo_map_near").show();
    $("#photo_map_far").hide();
  }).bind("mouseout", function(){
    $("#photo_map_near").hide();
    $("#photo_map_far").show();
  });

});