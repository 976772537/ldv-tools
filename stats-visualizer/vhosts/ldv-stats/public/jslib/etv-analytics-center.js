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

// Calculate original widths of text fields just once (they are set up in
// CSS).
var originalErrorTraceWidth;
var originalTabsWidth;
$(document).ready(function() {
  originalErrorTraceWidth = $('#ETVErrorTrace').width();
  originalTabsWidth = $('#ETVTabs').width();
});

// Resize widths of text fields to fit the screen (#4417).
function resizeTextFieldWidths() {
  // Indeed, this is a magic formula.
  var screenWidth = $('#SSHeader').width() - 20;
  var newErrorTraceWidth = Math.round(screenWidth / 2);
  var newTabsWidth = Math.round(screenWidth / 2);
  // Resize just if sum of new widths will be more then sum of the original ones.
  if (originalErrorTraceWidth + originalTabsWidth < screenWidth) {
    $('#ETVErrorTrace').width(newErrorTraceWidth);
    $('#ETVTabs').width(newTabsWidth);
  }
  else {
    $('#ETVErrorTrace').width(originalErrorTraceWidth);
    $('#ETVTabs').width(originalTabsWidth);
  }
  resizeTabWidths(true);
}

$(document).ready(resizeTextFieldWidths);
$(window).resize(resizeTextFieldWidths);
