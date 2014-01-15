/*
 * Copyright (C) 2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Plugin allows local entities expanding.
// Get an entity id.
function getIdOfExpandEntity(entity) {
  var entityIdAttr = entity.attr('id');
  if (!entityIdAttr) {
    alert("Entity hasn't an id attribute");
    return '';
  }
  var id = entityIdAttr.match(/\d+$/);
  if (!id) {
    alert("An id attribute has incorrect format");
    return '';
  }
  return id[0];
}
// Expand or collapse a given entity body.
$(document).ready(function() {
  $('a.ETVExpand').toggle(function() {
    var id = getIdOfExpandEntity($(this));
    $('#ETV' + id).hide();
    $(this).html('+');
  } , function() {
    var id = getIdOfExpandEntity($(this));
    $('#ETV' + id).show();
    $(this).html('-');
  });
});

// Simple tabs plugin.
var tabNoActiveWidth;

// Resize tabs to fit the available width.
function resizeTabWidths(isResize) {
  var tabsNumb = $('#ETVTabsHeader li').length;
  var tabsHeaderWidth = $('#ETVTabs').width();
  // If there is not an active tab, then make the first tab active.
  if (!isResize) {
    $('#ETVTabs div').hide();
    $('#ETVTabs div:first').show();
    $('#ETVTabsHeader li:first').addClass('ETVActive');
  }
  var tabActiveWidth = $('#ETVTabsHeader li.ETVActive').width();
  // Set up nonactive tab widths if there is more then one tab.
  if (tabsNumb > 1) {
    tabNoActiveWidth = Math.floor((tabsHeaderWidth - tabActiveWidth - 2) / (tabsNumb - 1) - 2);
    $('#ETVTabsHeader li').not('.ETVActive').width(tabNoActiveWidth);
  }
}

$(document).ready(function() {
  resizeTabWidths(false);
});

// Allow to choose a current tab.
$(document).ready(function() {
  $('#ETVTabsHeader li a').click(function() {
    $('#ETVTabsHeader li').removeClass('ETVActive');
    $(this).parent().removeAttr('style').addClass('ETVActive');
    $('#ETVTabsHeader li').not('.ETVActive').width(tabNoActiveWidth);
    var currentLink = $(this).attr('href');
    var linkPosition = currentLink.lastIndexOf('#');
    currentTabShort = currentLink.substring(linkPosition);
    $('#ETVTabs div').hide();
    $(currentTabShort).show();
    return false;
  });
});

// Plugin that relates error trace with corresponding source code.
$(document).ready(function() {
  $('.ETVLN a').click(function() {
    $('#ETVTabs ul li').removeClass('ETVActive');
    var currentLink = $(this).attr('href');
    var linkPosition = currentLink.lastIndexOf('#');
    var linePosition = currentLink.lastIndexOf(':');
    currentTab = currentLink.substring(0, linePosition);
    currentTabShort = currentLink.substring(linkPosition, linePosition);
    currentLineShort = currentLink.substring(linkPosition);
    $('#ETVTabs div').hide();
    $('#ETVTabsHeader li a[href=' + currentTabShort + ']').parent().removeAttr('style').addClass('ETVActive');
    $('#ETVTabsHeader li').not('.ETVActive').width(tabNoActiveWidth);
    $(currentTabShort).show();
    $('#ETVTabs div span').removeClass('ETVMarked');
    var srcStr = $('a[name="' + currentLineShort.substring(1) + '"]').parent();
    if (srcStr.length < 1) {
      alert("Can't find related source code");
      return '';
    }
    srcStr.addClass('ETVMarked');
    srcStr.parent().scrollTop(0).scrollTop(srcStr.position().top - srcStr.parent().position().top - 50);
    return false;
  });
});

// Expand/collapse 'Others' menu.
$(document).ready(function() {
  $('#ETVMenuOthers li').hover(function() {
    $(this).addClass('ETVactive');
    $(this).find('form').show();
  }, function() {
    $(this).removeClass('ETVactive');
    $(this).find('form').hide();
  })
})

// At the beginning reset all expanding checkboxes since they are stored for a
// given session.
$(document).ready(function() {
  $('#ETVErrorTraceHeader input:checkbox').attr('checked', true);
});

// Plugin allows expand/collapse enitity classes.
var showEntityClass = {
    'ETVCallBody': 1
  , 'ETVBlock': 1
  , 'ETVCallInit' : 0
  , 'ETVCallInitBody' : 0
  , 'ETVCallEntry' : 1
  , 'ETVCallEntryBody' : 1
  , 'ETVCall' : 1
  , 'ETVCallSkip' : 1
  , 'ETVCallFormalParamName' : 1
  , 'ETVDecl': 0
  , 'ETVAssume' : 1
  , 'ETVAssumeCond' : 1
  , 'ETVRet' : 1
  , 'ETVRetVal' : 1
  , 'ETVDEGInit' : 0
  , 'ETVDEGCall' : 1
  , 'ETVModelCall' : 1
  , 'ETVModelCallBody' : 1
  , 'ETVModelAssert' : 1
  , 'ETVModelChangeState' : 1
  , 'ETVModelCallCall' : 1
  , 'ETVModelCallCallBody' : 1
  , 'ETVModelRet' : 1
  , 'ETVModelOther' : 1
  , 'ETVI' : 1
  , 'ETVLN' : 1
  , 'ETVExpand' : 1
  , 'ETVIntellectualCallBody' : 0
};

$.each(showEntityClass, function(entity_class, isshow) {
  $(document).ready(function() {
    $('a.#' + entity_class + 'Expand').toggle(function() {
      $('.' + entity_class).each(function() {
        if ($(this).css('display') != 'none') {
          $(this).hide();
          $('#' + $(this).attr('id') + 'Expand').click();
        }
      });
    }, function() {
      $('.' + entity_class).each(function() {
        if ($(this).css('display') == 'none') {
          $(this).show();
          $('#' + $(this).attr('id') + 'Expand').click();
        }
      });
    });
  });

  $(document).ready(function() {
    $('#' + entity_class + 'Menu').change(function() {
      $('a.#' + entity_class + 'Expand').click();
    });
  });
});

// Print intellectual global expanding plugin that allows to collapse all
// function bodies that don't contain model function calls at any level of
// depth.
$(document).ready(function() {
  $('a.#ETVIntellectualCallBodyExpand').toggle(function() {
    $('.ETVCallBody, .ETVDEGCall').each(function() {
      var isFuncBodyHasModelFuncCall = false;
      $(this).find('div').each(function() {
        if ($(this).hasClass('ETVModelCall')) {
          isFuncBodyHasModelFuncCall = true;
        }
      });
      if (!isFuncBodyHasModelFuncCall) {
        if ($(this).css('display') != 'none') {
          $('#ETVExpand' + getIdOfExpandEntity($(this))).click();
        }
      }
    });
  }, function() {
    $('.ETVCallBody, .ETVDEGCall').each(function() {
      var isFuncBodyHasModelFuncCall = false;
      $(this).find('div').each(function() {
        if ($(this).hasClass('ETVModelCall')) {
          isFuncBodyHasModelFuncCall = true;
        }
      });
      if (!isFuncBodyHasModelFuncCall) {
        if ($(this).css('display') == 'none') {
          $('#ETVExpand' + getIdOfExpandEntity($(this))).click();
        }
      }
    });
  });
});

// Hide those elements of error trace that aren't very usefull.
$.each(showEntityClass, function(entity_class, isshow) {
  $(document).ready(function() {
    if (!isshow)
      $('#' + entity_class + 'Menu').change().attr('checked', false);
  });
});
