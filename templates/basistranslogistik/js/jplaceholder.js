/*
 * version: jplaceholder 1.0.0 24.11.2012
 * author: hmelii
 * email: anufry@inbox.ru
 */
(function($) {
	var settings;
	$.fn.jplaceholder = function( options ) {
		return this.each(function()	{
			settings = $.extend({
			
			},options||{});
			var $obj = $(this);
			var $obj__placeholderValue = $obj.attr('placeholder');
			
			$obj.on({
				'focus' : function() {
					if ($obj.val() == $obj__placeholderValue) {
						$obj.val('');
						$obj.removeClass('placeholder');
					}
				},
				'blur' : function(){
					if ($obj.val() == '' || $obj.val() == $obj.attr('placeholder')) {
						$obj.addClass('placeholder');
						$obj.val($obj.attr('placeholder'));
					}	
				}
				
			}).blur();
		});
		
		
		
	};
})(jQuery);