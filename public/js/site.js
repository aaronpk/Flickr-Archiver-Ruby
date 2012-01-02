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

  /**
   * Photo size dropdown
   */
  $(".photo-sizes a.dropdown-toggle").bind("click", function(){
    if($(".photo-sizes a.dropdown-toggle").hasClass("closed")) {
      $(".photo-sizes a.dropdown-toggle").removeClass("closed").addClass("open");
      $(".photo-sizes .hidden").removeClass("hidden");
    } else {
      $(".photo-sizes a.dropdown-toggle").removeClass("open").addClass("closed");
      $(".photo-sizes .start-hidden").addClass("hidden");
    }
  });

});