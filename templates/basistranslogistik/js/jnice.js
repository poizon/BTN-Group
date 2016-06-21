
(function ($) {

    var observeDOM = (function(){
        var MutationObserver = window.MutationObserver || window.WebKitMutationObserver,
            eventListenerSupported = window.addEventListener;
        return function(obj, callback){
            if( MutationObserver ){
                // define a new observer
                var obs = new MutationObserver(function(mutations, observer){
                    if( mutations[0].addedNodes.length || mutations[0].removedNodes.length )
                        callback();
                });
                // have the observer observe foo for changes in children
                obs.observe( obj, { childList:true, subtree:true });
            }
            else if ( eventListenerSupported ){
                obj.addEventListener('DOMNodeInserted', callback, false);
                obj.addEventListener('DOMNodeRemoved', callback, false);
            }
        }
    })();



    $.fn.jnice = function (options) {

        return this.each(function() {

            var $form = $(this);
            var $checkboxes = $form.find('input[type=checkbox]');
            var $radios = $form.find('input[type=radio]:not(.no-nice)');
            var $selects = $form.find('select');
            var $files = $form.find('input[type=file]');

            var settings = $.extend({
                checkbox: true,
                radio: true,
                select: true,
                file: true
            }, options || {});

            if (settings.file) {

                $files.each(function(){

                    var $file = $(this);
                    var reWin = /.*\\(.*)/;

                    var reUnix = /.*\/(.*)/;

                    var fileAttrClass = $file.attr('class') || '';
                    var fileAttrStyle = $file.attr('style') || '';

                    var $jfile = $('<span />', {
                        'class'   : 'js-file '+fileAttrClass,
                        'style'   : fileAttrStyle
                    });

                    var $jfileVal = $('<span />', {
                        'class'   : 'js-file_val'
                    });

                    var $jfileBtn = $('<span />', {
                        'class'   : 'js-file_btn'
                    });

                    var $jfileWrap = $('<span />', {
                        'class'   : 'js-file_wrap'
                    });

                    $file.replaceWith($jfile);

                    $jfileWrap.append($file)

                    $jfile.append($jfileWrap,$jfileVal,$jfileBtn);

                    $file.change(function(){

                        var val = $file.val();
                        var fileTitle = val.replace(reWin, "$1");
                        fileTitle = fileTitle.replace(reUnix, "$1");


                        $jfileVal.html(fileTitle);
                    });


                });
            }

            /*checkbox*/
            if (settings.checkbox) {
                $checkboxes.each(function() {
                    var $checkbox = $(this);
                    var checkboxAttrClass = $checkbox.attr('class') || '';
                    var checkboxAttrStyle = $checkbox.attr('style') || '';
                    var checkboxAttrChecked = this.checked?' checked':'';
                    var $jcheckbox = $('<label />', {
                                        'class' : 'js-checkbox '+checkboxAttrClass+checkboxAttrChecked,
                                        'style' : checkboxAttrStyle
                                     });

                    $checkbox.wrap($jcheckbox);

                    $checkbox.click(function(){
                        $checkbox.parents('.js-checkbox:first').toggleClass('checked');
                    });
                });
            }

            /*radio*/
            if (settings.radio) {
                $radios.each(function() {
                    var $radio = $(this);
                    var radioAttrClass = $radio.attr('class') || '';
                    var radioAttrStyle = $radio.attr('style') || '';
                    var radioAttrChecked = this.checked?' checked':'';
                    var radioAttrName = $radio.attr('name') || '';

                    var $jradio = $('<label />', {
                        'class' : 'js-radio '+radioAttrClass+radioAttrChecked,
                        'style' : radioAttrStyle,
                        'rel'   : radioAttrName
                    });

                    $radio.wrap($jradio);

                    $radio.click(function() {

                        $('label.js-radio[rel="'+radioAttrName+'"]').removeClass('checked');
                        $radio.parents('.js-radio:first').addClass('checked');
                    });
                });
            }

            /*selects*/
            if (settings.select) {
                $selects.each(function (index) {

                    var $select = $(this);

                    var $class = $select.attr('class');

                    $select.addClass('hide').wrap('<span class="jselect ' + $class + '" style="' + ($select.attr('style') && $select.attr('style') ) + '"><div class="jNiceSelectWrapper"></div></span>');

                    var $wrapper = $select.parent();

                    $wrapper.prepend('<a class="selectedItem" href="#"><span class="text" /></a><ul class="s"></ul>');
                    var $ul = $('ul.s', $wrapper);

                    $('option', $select).each(function (i) {
                        $ul.append('<li><a href="#" index="' + i + '">' + this.text + '</a></li>');
                    });
                    $ul.hide().on('click', 'a', function () {
                        var $obj = $(this);
                        $('a.selected', $wrapper).removeClass('selected');
                        $obj.addClass('selected');
                        if ($select.prop('selectedIndex') != $obj.attr('index') && $select.change) {
                            $select.prop('selectedIndex', $obj.attr('index'));
                            $select.change();
                        }
                        $select.prop('selectedIndex', $obj.attr('index'));
                        $wrapper.find('span.text').html($obj.html());
                        $ul.hide();
                        return false;
                    });
                    $('a:eq(' + $select.prop('selectedIndex') + ')', $ul).click();

                    observeDOM( $select[0] ,function(){
                        $ul.html('');
                        $('option', $select).each(function (i) {
                            $ul.append('<li><a href="#" index="' + i + '">' + this.text + '</a></li>');
                        });
                        var $selectedElement = $('a:eq(' + $select.prop('selectedIndex') + ')', $ul).addClass('selected');
                        $wrapper.find('span.text').text($selectedElement.text());
                    });

                    $select.on('change', function(){

                        $ul.html('');
                        $('option', $select).each(function (i) {
                            $ul.append('<li><a href="#" index="' + i + '">' + this.text + '</a></li>');
                        });

                        var $selectedElement = $('a:eq(' + $select.prop('selectedIndex') + ')', $ul).addClass('selected');
                        setTimeout(function(){
                            $wrapper.find('span.text').text($selectedElement.text());
                        },100);
                    });
                });
                $('a.selectedItem', this).click(function () {
                    var $ul = $(this).siblings('ul');
                    if ($ul.css('display') == 'none') {
                        hideSelect();
                    }
                    $ul.slideToggle('fast', function () {
                        var offSet = parseInt(($('a.selected', $ul).prop('offsetTop') - $ul.prop('offsetTop')));
                        $ul.animate({scrollTop: offSet});
                    });

                    return false;
                });

                var hideSelect = function () {
                    $('.jNiceSelectWrapper ul:visible').hide();
                };

                var checkExternalClick = function (event) {
                    if ($(event.target).parents('.jselect').length === 0) {
                        hideSelect();
                    }
                };

                $(document).mousedown(checkExternalClick);


                var jReset = function (f) {
                    var sel;


                    $('div.jNiceSelectWrapper select', f).each(function () {

                        sel = ( this.selectedIndex < 0 ) ? 0 : this.selectedIndex;

                        $('ul', $(this).parent()).each(function () {

                            $('a:eq(' + sel + ')', this).click();
                        });
                    });

                    $(':checkbox', f).each(function () {
                        var $obj = $(this);
                        var $checked = $obj.prop('checked');
                        var $chk = $obj.parent('.js-checkbox');
                        $checked ? $chk.addClass('checked') : $chk.removeClass('checked');


                    });
                    $(':radio', f).each(function () {
                        var $obj = $(this);
                        var $checked = $obj.prop('checked');

                        var $chk = $obj.prev('a.js-radio');
                        //alert($chk.length)
                        $checked ? $chk.addClass('checked') : $chk.removeClass('checked');


                    });

                };

                $form.bind('reset', function () {
                    var f = this;
                    var action = function () {
                        jReset(f);
                    };
                    setTimeout(action, 10);
                });

            }

        });
    };
})(jQuery);