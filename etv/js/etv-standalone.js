/*
 * Copyright (C) 2013
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

// Calculate original widths and heights of text fields just once (they
// are set up in CSS).
var originalErrorTraceWidth;
var originalErrorTraceHeight;
var originalTabsWidth;
var originalSrcHeight;
$(document).ready(function() {
  originalErrorTraceWidth = $('#ETVErrorTrace').width();
  originalErrorTraceHeight = $('#ETVErrorTrace').height();
  originalTabsWidth = $('#ETVTabs').width();
  originalSrcHeight = $('.ETVSrc').height();
});

// Resize widths (#4417) and heights (#4581) of text fields to fit the
// screen.
function resizeTextFieldWidthsAndHeights() {
  // Indeed, this is a magic formula.
  var screenWidth = $(window).width() - 40;
  // Keep the ratio between text field widths.
  var newErrorTraceWidth = Math.round(screenWidth * (originalErrorTraceWidth / (originalErrorTraceWidth + originalTabsWidth)));
  var newTabsWidth = Math.round(screenWidth - newErrorTraceWidth);
  // Resize just if sum of new widths will be more then sum of the original ones.
  if (originalErrorTraceWidth + originalTabsWidth < screenWidth) {
    $('#ETVErrorTrace').width(newErrorTraceWidth);
    $('#ETVTabs').width(newTabsWidth);
  }
  resizeTabWidths(true);

  // One more magic formula.
  var screenHeight = $(window).height() - 100;
  // Resize just if new heights will be more then the original ones.
  if (originalErrorTraceHeight < screenHeight && originalSrcHeight < screenHeight) {
    $('#ETVErrorTrace').height(screenHeight);
    $('.ETVSrc').height(screenHeight);
  }
}

$(document).ready(resizeTextFieldWidthsAndHeights);
$(window).resize(resizeTextFieldWidthsAndHeights);
