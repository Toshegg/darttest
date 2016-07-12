// Copyright (c) 2016, toshegg. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'dart:core';
import 'dart:collection';
import "package:js/js.dart" show allowInterop;
import 'package:babylonjs_facade/babylon.dart' as Babylon;

CanvasElement canvas;
Babylon.Engine engine;
Babylon.Scene scene;
bool sceneChecked = false;

var initialPosition;
var savePositionButton;
var positionNameInput;
var positionsSelect;

HashMap<String, Babylon.Vector3> positions;

main() {

  canvas = document.getElementById("renderCanvas");
  canvas.style.width = "100%";
  canvas.style.height = "100%";
  engine = engine = new Babylon.Engine(canvas, true);

  savePositionButton = document.getElementById("savePosition");
  positionNameInput = document.getElementById("positionName");
  positionsSelect = document.getElementById("positions");

  positionsSelect.onChange.listen(_positionSelected);
  savePositionButton.onClick.listen(_savePosition);
  positions = new HashMap<String, Babylon.Vector3>();

  init();
}

init() {

  Babylon.SceneLoader.ForceFullSceneLoadingForIncremental = true;

  engine.resize();

  var dlCount = 0;
  Babylon.SceneLoader.Load("http://cdn.babylonjs.com/wwwbabylonjs/Scenes/Retail/", "Retail.babylon", engine, allowInterop(_onSuccess), allowInterop(_onProgress), allowInterop(_onError));

  engine.runRenderLoop(allowInterop(renderLoop));
}

void renderLoop () {

  if (scene != null) {
    if (!sceneChecked) {
      var remaining = scene.getWaitingItemsCount();
      engine.loadingUIText = "Streaming items..." + (remaining ? (remaining + " remaining") : "");
    }

    scene.render();

    if (scene.useDelayedTextureLoading) {
      var waiting = scene.getWaitingItemsCount();
      if (waiting > 0) {
        print("Streaming items..." + waiting + " remaining");
      } else {
        print("Streaming done.");
      }
    }
  }
}


void _onSuccess(Babylon.Scene newScene) {
  scene = newScene;

  scene.executeWhenReady(allowInterop(() {
    canvas.style.opacity = 1.toString();
    if (scene.activeCamera != null) {
      scene.activeCamera.attachControl(canvas);
      
      if (newScene.activeCamera is Babylon.FreeCamera ) {
        Babylon.FreeCamera cam = newScene.activeCamera;
        initialPosition = cam.position.clone();
        
        //cam.keysUp.add(87); // W
        //cam.keysDown.add(83); // S
        //cam.keysLeft.add(65); // A
        //cam.keysRight.add(68); // D
      }
    }

    sceneChecked = true;
  }));
}

void _onProgress(Object evt) {
  print(evt);
}

void _savePosition(event) {
  positions[positionNameInput.value] = scene.activeCamera.position.clone();

  OptionElement option = new Element.tag("option");
  option.text = positionNameInput.value;
  option.value = positionNameInput.value;
  
  positionsSelect.add(option, null);
  positionNameInput.value = null;
}

void _positionSelected(event) {
  if (positionsSelect.value != "") {
    scene.activeCamera.position = positions[positionsSelect.value].clone();
  } else {
    scene.activeCamera.position = initialPosition.clone();    
  }
}
void _onError(Babylon.Scene a) {
}
