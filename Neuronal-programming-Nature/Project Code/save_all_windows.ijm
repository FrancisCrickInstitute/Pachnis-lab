//Save all images that are currently open (will close them as well)
//I found this script on https://forum.image.sc/t/save-all-opened-images/11519, and hold no authorship on it. April 15 2019--Todd Fallesen

dir = getDirectory("Choose a Directory");
//ids=newArray(nImages);
for (i=0;i<nImages;i++) {
        selectImage(i+1);
        title = getTitle;
        print(title);
        //ids[i]=getImageID;

        saveAs("tiff", dir+title);
} 
run("Close All");