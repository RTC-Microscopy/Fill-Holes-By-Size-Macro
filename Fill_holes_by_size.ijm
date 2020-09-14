/**
 * Fill background holes in a binary image similar to the 'Fill holes' function, except that you can set the minimum and maximum size of the holes to fill.
 * 1) The size is based on the area of the background hole in the same units as the image (e.g. mu, inches, pixels).
 * 2) This macro has only been tested on binary images. What is considered background is determined by the setting Process > Binary > Options > Black background.
 * 3) Any background hole found is filled completely, regardless if there are any foreground segments (with potential holes) included within.
 * 4) A region of interest can be used to limit the scope of the macro. If no selection has been made (or a non-enclosed one such as a line), the whole image is used.
 */
macro Fill_holes_by_size
{
	// ***** Here you can configure the macro. *****
	// minVale and maxValue give the minimum and maximum area (in units defined by the image) of the holes to be filled. 
	// Use -1 if you wish the macro to ask you for that size value every time before running.
	// If you are only interested in a maximum value, set minValue to 0.
	// If you only wish for a minimum value, using 'getWidth() * getHeight()' is a good maximum (i.e. the area of the whole image).
	minValue = -1;
	maxValue = -1;
	// Should any background area that touches the edge of the image or the selection be excluded from being filled or not?
	excludeEdges = false;

	// See if the minimum and maximum area have been preset
	if(minValue < 0 || maxValue < 0)
	{
		// At least one preset is missing so ask the user for it.
		Dialog.create("Select area size");
		Dialog.addMessage("Please select the minimum and/or maximum area of the holes to fill");
		if(minValue < 0)
		{
  			Dialog.addNumber("Minimum area", 0);
		}
		if(maxValue < 0) 
		{
  			Dialog.addNumber("Maximum area", getWidth() * getHeight());
		}
  		Dialog.show();

  		// Collect the user-chosen values from the dialog, depending on which area values have not been preset.
		if(minValue < 0)
		{
  			minValue = Dialog.getNumber();
		}
		if(maxValue < 0) 
		{
  		maxValue = Dialog.getNumber();
		}
	}

	// Use the correct text to exclude the background areas on the edge (or not). 
	edges = "";
	if(excludeEdges)
	{
		edges = "exclude "; 
	}

	// Count the existing number of areas in the roiManager. We don't want to change these.
	nrOfRois = roiManager("count");
	hasSelection = selectionType() >= 0;  // A type of -1 means no selection.
	if(hasSelection)
	{
		// We have a selection, work with that.
		roiManager("add");
	}

	// Now let's get any background holes that need filling.
	// We detect these by inverting the image and counting the now foreground areas.
	run("Invert");
	run("Analyze Particles...", "size=" + minValue + "-" + maxValue + " " + edges + "add");  // The holes will each be represented by a ROI in the roiManager.
	holesIndex = nrOfRois + hasSelection;  // The index of the first hole (if any)
	// Store the ROI indexes of any holes that need to be filled.
	holeIndexes = newArray();
	if(holesIndex < roiManager("count"))  // The ROI count is beyond what the first hole index should be, so applicable holes have been found.
	{
		roiManager("show none");
		for (j = holesIndex; j < roiManager("count"); j++) 
		{
			holeIndexes = Array.concat(holeIndexes, j);
		}
	}

	// Restore the proper foreground/background by inverting back (only in the original selection if any).
	if(hasSelection)
	{
		roiManager("select", nrOfRois);
	}
	run("Invert");

	// Now go through all the hole ROIs and fill them.
	for (j = holeIndexes.length - 1; j >= 0 ; j--) 
	{
		roiManager("select", holeIndexes[j]);		
		fill();
		roiManager("delete");  // Remove the hole ROI from the manager. Leave no clutter.
	}

	// Make sure that the original selection (or lack thereof) is restored.
	if(hasSelection)
	{
		// There was a selection, so reselect it.
		roiManager("select", nrOfRois);
		// Remove the ROI version of the selection that we added to the manager.
		roiManager("Delete");
	}
	else 
	{
		// No previous selection, so make sure it stays that way.
		run("Select None");
	}
}
