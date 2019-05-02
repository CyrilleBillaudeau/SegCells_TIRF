run("Close All");
roiManager("reset");
run("Threshold...");
path = File.openDialog("Select TIRF acquisition file");
imgPath = File.getParent(path);
imgFilename = File.getName(path);
open(path);
rename("orig");
//run("Subtract Background...", "rolling=10 stack");
run("Duplicate...", "title=mask duplicate");

setAutoThreshold("RenyiEntropy dark stack");
waitForUser("convert to mask");
run("Z Project...", "projection=[Max Intensity]");
selectWindow("mask");
close();
selectWindow("MAX_mask");
rename("mask");
/*
path_mask_simTIRF=replace(path,"avg.tif","mask.tif");
run("Text Image... ", "open="+path_mask_simTIRF);
run("Scale...", "x=0.5 y=0.5 width=512 height=512 interpolation=Bilinear average create title=tmp");
selectWindow("TIRF488_cam2_0_mask.tif");
close();
selectWindow("tmp");
rename("TIRF488_cam2_0_mask.tif");
run("Set Label Map", "colormap=[Golden angle] background=Black shuffle");
*/
selectWindow("mask");
setTool("wand");
waitForUser("select ROI to keep");
setBackgroundColor(0, 0, 0);
run("Clear Outside");

run("Select None");
run("Fill Holes");

setTool("line");
setForegroundColor(0, 0, 0);
waitForUser("modify ROI if needed (separate cells, remove ...)");


run("Select None");
run("Analyze Particles...", "add");

roiManager("Show None");
//run("Set Measurements...", "area center redirect=None decimal=3");
run("Set Measurements...", "area mean center redirect=None decimal=3");
run("Clear Results");
updateResults;
roiManager("Measure");

nROI=roiManager("count");
for (iROI=0;iROI<nROI;iROI++) {
	setResult("roiID", iROI, iROI+1);
	roiManager("Select",iROI);
	run("Multiply...", "value=0");
	run("Add...", "value="+(1+iROI));	
}
setMinAndMax(1, nROI);
run("Select None");
run("Clear Results");
updateResults;
roiManager("Measure");

doMerge=true;
setTool("multipoint");
selectWindow("mask");
run("Set Label Map", "colormap=[Golden angle] background=Black shuffle");

while (doMerge) {
	//selectionType() ;1=oval
	waitForUser("Select ROI to combine\nor draw oval to escape");
	if (selectionType()==1) {
		doMerge = false;		
	} else {
	
		run("Measure");
	
		nROI_part=nResults-nROI;
		print("total roi to be combine:",nROI_part);
		tab_ROI_combine=newArray(nROI_part);	
		for (iRes=nROI;iRes<nResults;iRes++) {
			tab_ROI_combine[iRes-nROI]=getResult("Mean",iRes);
		}
		Array.getStatistics(tab_ROI_combine, groupID, max, mean, stdDev);
		
		Array.print(tab_ROI_combine);
		if (groupID>0) {
			print("after comnination, final ID_ROI: ",groupID);
			for (iPart=0;iPart<nROI_part;iPart++) {
				print("select ROI#",tab_ROI_combine[iPart]);
				roiManager("Select",tab_ROI_combine[iPart]-1);
				run("Multiply...", "value=0");
				run("Add...", "value="+groupID);	
				print("set ID to:",groupID);
			}
		} else {
			print("some ROIs will be removed from analysis");
			for (iPart=0;iPart<nROI_part;iPart++) {
				print("select ROI#",tab_ROI_combine[iPart]);
				if ((tab_ROI_combine[iPart]-1) != -1) {
					roiManager("Select",tab_ROI_combine[iPart]-1);
					run("Multiply...", "value=0");
					run("Add...", "value="+groupID);	
					print("set ID to:",groupID);
				}
			}
		}
		
		run("Clear Results");
		updateResults;
		run("Select None");
		roiManager("Measure");
		run("Set Label Map", "colormap=[Golden angle] background=Black shuffle");
	}
	
}
		
initROI=newArray(nResults);
nRemove=0;
for (iROI=0;iROI<nResults;iROI++) {
	initROI[iROI]=getResult("Mean",iROI);
	if (initROI[iROI]==0) {
		nRemove=nRemove+1;
		setResult("Mean",iROI,1000);
	}
}
print("",nRemove," ROI will be removed"); 
Array.getStatistics(initROI, minID, max, mean, stdDev);
Array.print(initROI);
ind_sortedROI=Array.rankPositions(initROI);
Array.print(ind_sortedROI);
sorted_ROI=Array.sort(initROI);
//sorted_ROI = Array.slice(sorted_ROI, nRemove, sorted_ROI.length);  
Array.print(sorted_ROI);

finalROI=newArray(nResults);
curID=1;
finalROI[0]=curID;
for (iROI=1;iROI<(nResults);iROI++) {
	if (sorted_ROI[iROI]!=sorted_ROI[iROI-1]) {
		curID=curID+1;		
	}
	finalROI[iROI]=curID;
}
Array.print(finalROI);

for  (iROI=0;iROI<(nResults);iROI++) {
	curID=ind_sortedROI[iROI];
	if (getResult("Mean",curID) != 1000) {
		setResult("roiID",curID,finalROI[iROI]);
	} else {
		setResult("roiID",curID,1000);
	}
}

for (iROI=0;iROI<nResults;iROI++) {
	curID=getResult("roiID",iROI);
	if (curID != 1000) {
		roiManager("Select",iROI);
		run("Multiply...", "value=0");
		run("Add...", "value="+curID);	
	} else {
		roiManager("Select",iROI);
		run("Multiply...", "value=0");		
	}
}
Array.getStatistics(finalROI, min, totalROI, mean, stdDev);
run("Select None");
setMinAndMax(0, totalROI);

path_mask_avgTIRF=replace(path,"avg.tif","mask_avg.tif");
saveAs("Text Image", path_mask_avgTIRF);
