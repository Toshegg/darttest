// Copyright (c) 2016, toshegg. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'dart:core';
import 'dart:collection';
import 'dart:convert';
import "package:js/js.dart" show allowInterop;
import 'package:babylonjs_facade/babylon.dart' as Babylon;

CanvasElement canvas;
Babylon.Engine engine;
Babylon.Scene scene;
bool sceneChecked = false;

var initialPosition;
var initialRotation;
var savePositionButton;
var positionNameInput;
var positionsSelect;
var inputFocused;

class Position {
  Babylon.Vector3 position;
  Babylon.Vector3 rotation;

  Position (Babylon.Vector3 _p, Babylon.Vector3 _r) {
    position = _p;
    rotation = _r;
  }

  String toJson() {
    return '{"position": ${vectorToString(position)}, "rotation": ${vectorToString(rotation)}}';
  }
}

HashMap<String, Position> positions;

main() {

  canvas = document.getElementById("renderCanvas");
  canvas.style.width = "100%";
  canvas.style.height = "100%";
  engine = new Babylon.Engine(canvas, true);

  savePositionButton = document.getElementById("savePosition");
  positionNameInput = document.getElementById("positionName");
  positionsSelect = document.getElementById("positions");

  positionNameInput.onFocus.listen((e) => inputFocused = true);
  positionNameInput.onBlur.listen((e) => inputFocused = false);

  Element.keyDownEvent.forTarget(document.body, useCapture: true).listen((e) {
    if (inputFocused) {
      e.stopPropagation();
    }
  });

  positionsSelect.onChange.listen(_positionSelected);
  savePositionButton.onClick.listen(_savePosition);

  positions = new HashMap<String, Position>();

  if (window.localStorage.length > 0) {
    restorePositions();
  }

  init();
}

init() {

  Babylon.SceneLoader.ForceFullSceneLoadingForIncremental = true;

  engine.resize();

  var dlCount = 0;
  
  loadScene(createScene());

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

Babylon.Scene createScene() {
    var scene = new Babylon.Scene(engine);

    //Create a light
    var light = new Babylon.PointLight("Omni", new Babylon.Vector3(1,60,1), scene);

    var camera = new Babylon.FreeCamera("Camera", new Babylon.Vector3(1,60,1), scene);
    //Creation of 6 spheres
    var sphere1 = Babylon.Mesh.CreateSphere("Sphere1", 10.0, 9.0, scene, false, 0);
    var sphere2 = Babylon.Mesh.CreateSphere("Sphere2", 2.0, 9.0, scene, false, 0);//Only two segments
    var sphere3 = Babylon.Mesh.CreateSphere("Sphere3", 10.0, 9.0, scene, false, 0);
    var sphere4 = Babylon.Mesh.CreateSphere("Sphere4", 10.0, 9.0, scene, false, 0);
    var sphere5 = Babylon.Mesh.CreateSphere("Sphere5", 10.0, 9.0, scene, false, 0);
    var sphere6 = Babylon.Mesh.CreateSphere("Sphere6", 10.0, 9.0, scene, false, 0);

    //Position the spheres
    sphere1.position.x = 40;
    sphere2.position.x = 25;
    sphere3.position.x = 10;
    sphere4.position.x = -5;
    sphere5.position.x = -20;
    sphere6.position.x = -35;

    //Creation of a plane
    var plane = Babylon.Mesh.CreatePlane("plane", 120, scene, false, 0);
    plane.position.y = -5;
    plane.rotation.x = 3.14/2;

    //Creation of a material with wireFrame
    var materialSphere1 = new Babylon.StandardMaterial("texture1", scene);
    materialSphere1.wireframe = true;

    //Creation of a red material with alpha
    var materialSphere2 = new Babylon.StandardMaterial("texture2", scene);
    materialSphere2.diffuseColor = new Babylon.Color3(1, 0, 0); //Red
    materialSphere2.alpha = 0.3;

    //Creation of a material with an image texture
    var materialSphere3 = new Babylon.StandardMaterial("texture3", scene);
    materialSphere3.diffuseTexture = new Babylon.Texture("textures/misc.jpg", scene);

    //Creation of a material with translated texture
    var materialSphere4 = new Babylon.StandardMaterial("texture4", scene);
    materialSphere4.diffuseTexture = new Babylon.Texture("textures/misc.jpg", scene);
    materialSphere4.diffuseTexture.vOffset = 0.1;//Vertical offset of 10%
    materialSphere4.diffuseTexture.uOffset = 0.4;//Horizontal offset of 40%

    //Creation of a material with an alpha texture
    var materialSphere5 = new Babylon.StandardMaterial("texture5", scene);
    materialSphere5.diffuseTexture = new Babylon.Texture("textures/tree.jpg", scene);
    materialSphere5.diffuseTexture.hasAlpha = true;//Has an alpha

    //Creation of a material and show all the faces
    var materialSphere6 = new Babylon.StandardMaterial("texture6", scene);
    materialSphere6.diffuseTexture = new Babylon.Texture("textures/tree.jpg", scene);
    materialSphere6.diffuseTexture.hasAlpha = true;//Have an alpha
    materialSphere6.backFaceCulling = false;//Show all the faces of the element

    //Creation of a repeated textured material
    var materialPlane = new Babylon.StandardMaterial("texturePlane", scene);
    materialPlane.diffuseTexture = new Babylon.Texture("textures/grass.jpg", scene);
    materialPlane.diffuseTexture.uScale = 5.0;//Repeat 5 times on the Vertical Axes
    materialPlane.diffuseTexture.vScale = 5.0;//Repeat 5 times on the Horizontal Axes
    materialPlane.backFaceCulling = false;//Always show the front and the back of an element

    //Apply the materials to meshes
    sphere1.material = materialSphere1;
    sphere2.material = materialSphere2;

    sphere3.material = materialSphere3;
    sphere4.material = materialSphere4;

    sphere5.material = materialSphere5;
    sphere6.material = materialSphere6;

    plane.material = materialPlane;

    return scene;
}

void loadScene(Babylon.Scene newScene) {
  scene = newScene;

  scene.executeWhenReady(allowInterop(() {
    canvas.style.opacity = 1.toString();
    if (scene.activeCamera != null) {
      scene.activeCamera.attachControl(canvas);
      
      if (newScene.activeCamera is Babylon.FreeCamera ) {
        Babylon.FreeCamera cam = newScene.activeCamera;
        cam.applyGravity = false;
        cam.checkCollisions = false;
        cam.rotation = new Babylon.Vector3(1.4922565104551517, -1.1216478107819061, 0);

        initialPosition = cam.position.clone();
        initialRotation = cam.rotation.clone();
        
        cam.keysUp.add(87); // W
        cam.keysDown.add(83); // S
        cam.keysLeft.add(65); // A
        cam.keysRight.add(68); // D
      }
    }

    sceneChecked = true;
  }));
}

void _savePosition(event) {
  Babylon.FreeCamera cam = scene.activeCamera;

  var position = cam.position.clone();
  var rotation = cam.rotation.clone();
  var name = positionNameInput.value;

  positions[name] = new Position(position, rotation);

  addElementToSelect(name);

  if (name != "") {
    window.localStorage[name] = positions[name].toJson();
  }
  positionNameInput.value = null;
}

void addElementToSelect(String value) {
  OptionElement option = new Element.tag("option");
  option.text = value;
  option.value = value;
  
  positionsSelect.add(option, null);
}

void _positionSelected(event) {
  Babylon.FreeCamera cam = scene.activeCamera;
  if (positionsSelect.value != "") {
    cam.position = positions[positionsSelect.value].position.clone();
    cam.rotation = positions[positionsSelect.value].rotation.clone();
  } else {
    cam.position = initialPosition.clone();    
    cam.rotation = initialRotation.clone();    
  }
}

String vectorToString(Babylon.Vector3 v) {
  return '{"x": ${v.x}, "y": ${v.y}, "z": ${v.z}}';
}

void restorePositions() {
  for (var key in window.localStorage.keys) {
    var position = JSON.decode(window.localStorage[key])['position'];
    var rotation = JSON.decode(window.localStorage[key])['rotation'];

    positions[key] = new Position(new Babylon.Vector3(position['x'], position['y'], position['z']), new Babylon.Vector3(rotation['x'], rotation['y'], rotation['z']));

    addElementToSelect(key);
  }
}
