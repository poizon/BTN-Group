/*
 * version: jmodal 4.1.1 19.04.2015
 * author: hmelii
 * email: anufry@inbox.ru
 */

(function ($) {

    var imgRegExp = /\.(jpg|gif|png|bmp|jpeg)(.*)?$/i;


    var methods = {

        init: function (options) {


            return this.each(function (index, element) {

                var settings = {
                    modalId: '#js-modal',
                    modalBodyClass: '.js-modal__body',
                    keyboard: true,
                    modalClassHide: 'hidden',
                    modalClassShow: 'show',
                    modalClassClose: 'js-modal_hide',
                    remote: null,
                    link: false,
                    template: true,
                    element: null,
                    beforeShow: function () {
                    },
                    afterShow: function () {
                    },
                    afterHide: function () {
                    },
                    beforeHide: function () {
                    }
                };

                var $element = $(element);

                var data = $element.data('modal');

                options = options || {};


                if (!$element.hasClass('js-modal_template') && $element.prop('tagName') != 'SCRIPT' && !options.link) {

                    options.template = false;
                    options.modalId = '#' + $element.attr('id');


                }


                if (data) {
                    settings = $.extend(data.settings, options || {});
                } else {
                    settings = $.extend(settings, options || {});
                }


                $element.data('modal', {
                    content: $element.html(),
                    settings: settings
                });


                data = $element.data('modal');


                //console.log('init');


            });
        },

        toggle: function () {

            return this.each(function (index, element) {
                var $element = $(element);
                var data = $element.data('modal');

                if (!data) {
                    $element.jmodal();
                    data = $element.data('modal');
                }

                data.isShown ? $element.jmodal('hide') : $element.jmodal('show');


            });

        },


        show: function () {

            return this.each(function (index, element) {

                var $element = $(element);
                var data = $element.data('modal');

                if (!data) {

                    $element.jmodal();
                    data = $element.data('modal');

                }

                if (methods.element) {
                    methods.newElement = $element;
                    methods.oldElement = methods.element;
                    methods.element.jmodal('hide');
                }


                var settings = data.settings;
                var $modal = $(settings.modalId);
                var $modalBody = $modal.find(settings.modalBodyClass);
                var $body = $(document.body);
                var $html = $(document.documentElement);
                var bodyWidth = $body.width();
                var htmlScrollTop = $html.scrollTop();

                methods.element = $element;
                methods.isShown = true;
                data.isShown = true;

                settings.beforeShow($modal[0], settings.element);

                if (!methods.newElement || (methods.newElement && methods.newElement.data('modal').settings.modalId != methods.oldElement.data('modal').settings.modalId)) {

                    $html
                        .data('modal', {
                            scrollTop: htmlScrollTop
                        })
                        .css('overflow', 'hidden')
                        .scrollTop(htmlScrollTop);


                    var bodyWidthWithoutHtmlScroll = $body.width();
                    var htmlScrollWidth = bodyWidthWithoutHtmlScroll - bodyWidth;

                    $html.addClass('modal_showen').css('paddingRight', htmlScrollWidth + 'px');



                    $modal.removeClass(settings.modalClassHide);

                    setTimeout(function() {
                        $modal.addClass(settings.modalClassShow);
                    }, 25);

                }


                methods.escape($element);
                methods.close($element);


                if (settings.link) {
                    var href = $element.attr('href');

                    if (href.match(imgRegExp)) {

                        var title = $element.attr('title') || '';
                        $modalBody.html('<img src="' + href + '" alt="' + title + '" />');


                        settings.afterShow($modal[0], settings.element);


                    } else if ($element.data('modal-type') == 'frame') {

                        $modalBody.html('<iframe id="modal_frame" name="modal_frame' + new Date().getTime() + '" frameborder="0" hspace="0" allowtransparency="true" src="' + href + '" width="640" height="390"></iframe>');


                        settings.afterShow($modal[0], settings.element);


                    } else {
                        $modalBody.load(href, function () {

                            settings.afterShow($modal[0], settings.element);

                        });

                    }
                } else {
                    if (settings.template) {

                        $modalBody.html(data.content);

                    }


                    settings.afterShow($modal[0], settings.element);

                }

                methods.newElement = null;


                //console.log('show');

            });

        },

        hide: function () {

            return this.each(function (index, element) {
                var $element = $(element);
                var data = $element.data('modal');
                if (!data) {
                    $element.jmodal();
                    data = $element.data('modal');
                }

                var settings = data.settings;
                var $modal = $(settings.modalId);
                var $modalBody = $modal.find(settings.modalBodyClass);
                var $html = $(document.documentElement);
                var htmlData = $html.data('modal');

                methods.element = null;

                methods.isShown = false;
                data.isShown = false;


                settings.beforeHide($modal[0], settings.element);


                //data.content = $modalBody.children().clone();
                if (settings.template) {
                    $modalBody.html('');
                }


                if (!methods.newElement || methods.newElement.data('modal').settings.modalId != settings.modalId) {
                    $modal.removeClass(settings.modalClassShow);
                    if (Modernizr.csstransitions) {
                        $modal.one('webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend', function() {
                            $modal.addClass(settings.modalClassHide);
                            $html.removeClass('modal_showen').css({'overflow': '', 'paddingRight': ''}).scrollTop(htmlData.scrollTop);
                        });
                    } else {
                        $modal.addClass(settings.modalClassHide);
                        $html.removeClass('modal_showen').css({'overflow': '', 'paddingRight': ''}).scrollTop(htmlData.scrollTop);
                    }
                }

                methods.escape($element);
                methods.close($element);


                settings.afterHide($modal[0], settings.element);


                //console.log('hide');

            });


        },

        close: function ($element) {
            var $html = $(document.documentElement);
            var data = $element.data('modal');
            var settings = data.settings;

            if (methods.isShown) {
                //console.log('добавили close');
                $html.on('click.dissmiss.modal', function (event) {
                    if (event.target.className.indexOf(settings.modalClassClose) > -1) {
                        event.preventDefault();
                        $element.jmodal('hide');
                    }
                });
            } else if (!methods.isShown) {
                //console.log('убрали close');
                $html.off('click.dissmiss.modal');
            }
        },

        escape: function ($element) {
            var $html = $(document.documentElement);
            var data = $element.data('modal');
            var settings = data.settings;

            if (methods.isShown && settings.keyboard) {
                //console.log('добавили esc');
                $html.on('keyup.dismiss.modal', function (event) {
                    if (event.which == 27) {
                        $element.jmodal('hide');
                    }
                });
            } else if (!methods.isShown) {
                //console.log('убрали esc');
                $html.off('keyup.dismiss.modal');
            }

        }

    };

    $.fn.jmodal = function (method) {

        if (methods[method]) {

            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));

        } else if (typeof method === 'object' || !method) {

            return methods.init.apply(this, arguments);

        } else {

            $.error('Метод с именем ' + method + ' не существует для jmodal');

        }

    };

    $(document).on('click.modal.data-api', '.js-show_modal', function (event) {

        event.preventDefault();

        var $element = $(this);
        var href = $element.attr('href');
        var options = {};
        var $target;
        var template = true;

        if (!/#/.test(href)) {

            $target = $element;

            options = {
                link: true
            }


        } else {
            $target = $(href);


            options = {
                element: $element[0]

            };
        }


        $target.jmodal(options).jmodal('show');


    });


    $(document).on('click.modal.data-api', '.js-lightbox', function (event) {

        event.preventDefault();

        var $element = $(this);
        var href = $element.attr('href');

        var gal = $element.attr('data-lightbox');
        var $target = $element;

        var options = {
            link: true,
            modalId: '#modal_lightbox',
            afterShow: function (ele) {

                if ($element.attr('title')) {
                    $(ele).find('.modal_lightbox__title').html($element.attr('title')).show();
                } else {
                    $(ele).find('.modal_lightbox__title').hide();
                }

                if ($element.attr('href')) {
                    $(ele).find('.modal_lightbox__image').html('<img src="'+$element.attr('href')+'" alt="" />').show();
                    $(ele).find('.modal_lightbox__image img').load(function() {
                        $(ele).find('.modal__content').width($(ele).find('.modal_lightbox__image img').width()+'px');
                    });
                } else {
                    $(ele).find('.modal_lightbox__image').hide();
                }


                $element.each(function() {
                    $.each(this.attributes, function() {
                        // this.attributes is not a plain object, but an array
                        // of attribute nodes, which contain both the name and value
                        if(this.specified) {
                            //this.name, this.value
                            if (this.name.indexOf('data-lightbox-')>-1) {
                                $(ele).find('.modal_lightbox__'+this.name.replace('data-lightbox-','')).html(this.value);
                            }
                        }
                    });
                });


                $(ele).find('.modal_lightbox__prev').hide();
                $(ele).find('.modal_lightbox__next').hide();

                if (!gal) {
                    return;
                }

                var $gallery = $('[data-lightbox=' + gal + ']');

                var l = $gallery.length;

                var cur = 0;

                if (l < 2) {
                    return;
                }

                $gallery.each(function (index) {
                    if (this == $element[0]) {
                        cur = index;
                    }
                });


                $(ele).find('.modal_lightbox__prev').show();
                $(ele).find('.modal_lightbox__next').show();

                $(ele).find('.modal_lightbox__prev').off('click').on('click', function (event) {

                    event.preventDefault();

                    cur > 0 ? cur-- : cur = (l - 1);

                    $gallery.eq(cur).trigger('click');

                });

                $(ele).find('.modal_lightbox__next').off('click').on('click', function (event) {

                    event.preventDefault();

                    cur < (l - 1) ? cur++ : cur = 0;

                    $gallery.eq(cur).trigger('click');


                });


            }
        };


        $target.jmodal(options).jmodal('show');

    });

    $(function () {
        setTimeout(function () {
            $('.js-modal:not(.hidden),.js-modal_template:not(.hidden)').jmodal('show');

        }, 1);

    });


})(jQuery);