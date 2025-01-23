import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { ipcRenderer } from 'electron';
import { VRMLoaderPlugin } from '@pixiv/three-vrm';
import { createVRMAnimationClip, VRMAnimationLoaderPlugin } from "@pixiv/three-vrm-animation";

let currentVRM: any = undefined;
let currentVrmAnimation: any = undefined;
let currentMixer: any = undefined;

// Configuration
const modelPath = "./characters/K4-HH.vrm";
const vrmaPath = "./motions/VRMA_01.vrma";

let isDragging = false;
let startX = 0;
let startY = 0;
let startWindowX = 0;
let startWindowY = 0;

// シーンの設定
const scene = new THREE.Scene();

// イベントリスナーを追加
document.addEventListener('click', () => {
  if (currentVRM && currentVRM.humanoid) {
    const rightUpperArm = currentVRM.humanoid.getNormalizedBoneNode('rightUpperArm');
    if (rightUpperArm) {
      rightUpperArm.rotation.z -= 0.5; // 例: 右腕を上げる
    }
  }
});
document.addEventListener('dblclick', () => ipcRenderer.send('open-chat'));

// カメラの設定
const camera = new THREE.PerspectiveCamera(
  45,
  window.innerWidth / window.innerHeight,
  0.1,
  1000
);
camera.position.set(0, 1.5, -3);
camera.lookAt(0, 1, 0);

// レンダラーの設定
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setClearColor(0x000000, 0); // 背景を透明にする
document.body.appendChild(renderer.domElement);

// コントロールの設定
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 1, 0);
controls.screenSpacePanning = true;
controls.enableZoom = false;
controls.enableRotate = false;

// ライトの設定
const light = new THREE.DirectionalLight(0xffffff);
light.position.set(1, 1, 1).normalize();
scene.add(light);
scene.add(new THREE.AmbientLight(0xffffff, 0.5));

// VRMモデルのロード
const loader = new GLTFLoader();
loader.register((parser) => new VRMLoaderPlugin(parser));
loader.register((parser) => new VRMAnimationLoaderPlugin(parser));

loader.load(
  modelPath,
  (gltf) => {
    const vrm = gltf.userData.vrm;
    vrm.scene.rotation.y = Math.PI; // モデルを正面に向ける
    scene.add(vrm.scene);
    currentVRM = vrm;

    setTimeout(() => {
      if (currentVRM && currentVRM.expressionManager) {
        // currentVRM.expressionManager.setValue('happy', 1);
        console.log('Expression set to happy');
      } else {
        console.log('currentVRM or currentVRM.expressionManager is undefined');
      }
    }, 3000);
    initAnimationClip();
  },
  (progress) => console.log('Loading model...', 100.0 * (progress.loaded / progress.total), '%'),
  (error) => console.error(error)
);

loader.load(
  vrmaPath,
  (gltf) => {
    const vrmAnimations = gltf.userData.vrmAnimations;
    if (vrmAnimations == null) {
      return;
    }
    currentVrmAnimation = vrmAnimations[0] ?? null;
    initAnimationClip(); // VRMAモデルのロードが完了したらAnimationClipを初期化
  },
  (progress) => console.log('Loading model...', 100.0 * (progress.loaded / progress.total), '%'),
  (error) => console.error(error)
);

// ウィンドウリサイズ対応
window.addEventListener('resize', onWindowResize, false);
function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}

// アニメーションループ
function animate() {
  requestAnimationFrame(animate);
  const deltaTime = clock.getDelta();
  if (currentMixer) {
    currentMixer.update(deltaTime);
  }
  if (currentVRM) {
    currentVRM.update(deltaTime);
  }

  controls.update();
  renderer.render(scene, camera);
}

const clock = new THREE.Clock();
animate();

document.addEventListener('mousedown', (event) => {
  isDragging = true;
  startX = event.clientX;
  startY = event.clientY;
  startWindowX = window.screenX;
  startWindowY = window.screenY;
});

document.addEventListener('mousemove', (event) => {
  if (!isDragging) return;
  const x = event.clientX - startX;
  const y = event.clientY - startY;
  ipcRenderer.send('move-window', { x, y, startWindowX, startWindowY });
});

document.addEventListener('mouseup', () => {
  isDragging = false;
});

function initAnimationClip() {
  if (currentVRM && currentVrmAnimation) {
    currentMixer = new THREE.AnimationMixer(currentVRM.scene);
    const clip = createVRMAnimationClip(currentVrmAnimation, currentVRM);
    currentMixer.clipAction(clip).play();
  }
}
