# CameraManager Features :

● manage camera session 

● get image from camera 

● crop image in a frame

● scan barcode and get the image asynchronously  


# Requirements :

iOS 8.0+

Xcode 8.1+

Swift 3.0+ (Support Swift 4) 

---------------------------------------------------------------------------
**Demo :** 

![www gifcreator me_3krqfy](https://cloud.githubusercontent.com/assets/13133764/22628149/36ce4070-ebe4-11e6-9fd9-fdd3fb2ce42f.gif)

---------------------------------------------------------------------------

# Installation :

**CocoaPods :**


```
pod 'MFCameraManager'

```

**or download CustomCameraManagerClass directory and add it manually to your project**  

# Setup :

Now in your view add a UIView to storyboard view controller or programmetically initiate an UIView which will be your camera preview. then follow steps to display the camera : 

**If you just need the camera session and capturing image you have to use CameraManager.swift class, as it has StillImageOutput.** 

**but if you need the camera session to scan barcode beside capturing image you have to use ScanBarcodeCameraManager.swift class, as it has StillImageOutput.** 

**initial step**
---------------------------------------------------------------------------

Create a variable of which class you prefer (ScanBarcodeCameraManager.swift or CameraManager.swift) :

`  var cameraManager = CameraManager() `

or 

`  var cameraManager = ScanBarcodeCameraManager() `


from now on below 4 steps are similar in each class you instantiated :

1 - on your viewDidLoad setup the camera with your UIView created to show the camera preview inside it, and your camera position which its default is back :

`  cameraManager.captureSetup(in: self.cameraView, with: .back) `


2 - in viewWillApear delegate call this method : 

`   cameraManager.startRunning() `

3 - in viewDidDisapear delegate call below method :

` cameraManager.stopRunning() `

4 - to support landscape transitions add below code to viewWillTransition Delegate : 

` cameraManager.transitionCamera() `


**Features in CameraManager class**
----------------------------

- to capture an image showing on camera  : 

```
self.cameraManager.getcroppedImage { (UIImage, error) in

          //your code here to handle with error or if error == nil , get the UIImage 
}
```

- to get the image inside a frame or CGRect , give the frame as a params to getcroppedImage function like below : 

```
self.cameraManager.getcroppedImage(with: self.rectLayer.frame) {  (UIImage, error) in
         
       //your code here to handle with error or if error == nil , get the UIImage 
           
 }

```

**Features in ScanBarcodeCameraManager class**
----------------------------

- to get the scanned barcode and capture an image : 

should conform to protocol ScanBarcodeCameraManagerDelegate and : 

```
self.cameraManager.delegate = self

```

then implement the function to get the barcode objects and also the captured image :

```
func scanBarcodeCameraManagerDidRecognizeBarcode(barcode: Array<AVMetadataMachineReadableCodeObject>, image: UIImage?) {
        self.scanBarcodeCameraManager.stopRunning()
        print(barcode)
        // to whatever you like to the barcode objects and the image
        scanBarcodeCameraManager.startRunning()

    }
```

**Extra features in all classess**
----------------------------
- to enable torch mode use below code with level of torch mode default is 1 : 

`cameraManager.enableTorchMode(level: 1)`




# Communication :

- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, submit a pull request.
