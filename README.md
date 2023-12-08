# 防切边的球状特效

如果对您有所帮助，希望您给我个 Star！

![ezgif com-video-to-gif (2)](https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/17c7186a-d574-4a5f-a681-dcce273593f5)

## 应用示例

![ezgif com-video-to-gif (1)](https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/5c0e3297-8ca1-412f-ace7-1fd39c57b663)

## 简介

* 用 Unity 的 Particle System 制作特效的时候，经常需要用一个 Billboard 模式的片去实现一个球状特效（能量球、冲击波、爆闪等）

  > 内容为光球的片
  >
  > ![texture_ball](https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/4bcb158d-4e58-4e94-98fc-5eb2f82a3fff)

  > 实现的效果
  >
  > <img width="409" alt="微信图片_20231208121113" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/86f15276-be8c-488c-8fc1-1f348bce0731">

* 通过 Billboard，仅用 4 个顶点即可实现球状效果，对比使用球状网格，这样大大降低了 Cpu、Gpu 的消耗，但这种实现方式在高度不够的时候容易发生切片

    <img width="402" alt="1702009121826" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/c24abba2-2706-4914-9e02-deb946e15a76">

* 该解决方案通过顶点着色器控制网格的 6 个顶点的世界坐标、纹理采样坐标来解决上述提到的切边问题
  
    <img width="346" alt="1702010028933" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/4e0fc480-8470-4a8f-9242-80422cb4f14f">
    
* 目前该解决方案已应用到个人制作的各个特效中，效果稳定可靠，在使用上遇到问题或者有任何疑问，欢迎发送邮件到 2662774600@qq.com 进行反馈
  
## 缺点

* 需要指定当前地面的 Y 坐标

* 不支持旋转
    
## 运行 demo

* 安装 Unity 2018.4.12f1
  
* 运行场景 scene_index

## 使用手册

* Particle System 引用的材质中的着色器换成 Jiang/ParticleSystemFoldAdd（项目中需要有 shader_particle_system_fold.shader），Texture 设置为效果纹理，GroundY 设置为地面的 Y 坐标（默认为 0）
  
  <img width="313" alt="1702011472538" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/c28ce113-c494-4612-9689-07c464c7ab20">

* Particle System 的 Render Mode 改为 Mesh

  <img width="299" alt="1702011518788" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/261a49bd-204c-4d96-92cd-a1736f2417f6">

* 把网格设置成 ball_effect（项目中需要有 fbx_ball_effect.fbx）

  <img width="298" alt="1702011576149" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/62821795-db59-4654-a489-826fdf0ba50a">

* 勾选 Custom Vertex Streams
  
  <img width="296" alt="1702012289869" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/71401f48-1be3-4f8d-a866-355ee82f208e">

* 添加 Tangent、Center，注意次序不能乱

  <img width="296" alt="1702012552651" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/236a3cf5-2463-4f64-95f1-b3b445549788">

* 至此，所有发射出来的粒子都会自动防止地面切边

## 原理概述

fbx_ball_effect.fbx 中的网格 ball_effect 是一个自带折痕的片，网格数据中折痕与底部重合，所以外观上没看出来

<img width="311" alt="1702013250586" src="https://github.com/JULIUSJIANG/u3d_ball_effect/assets/33363444/8eb08419-51a9-48a0-a9c6-4ca93ef906af">

shader_particle_system_fold.shader 中的顶点着色器，用于决定如何对折网格 ball_effect 来达到效果：

* 粒子没与地板接触：此时效果相当于纯粹的 BillBoard

* 粒子下半与地板接触：上边不动，折痕自动置于被地板相切的位置，下边界也置于地板平面，但根据透视向摄像机平移

* 粒子上半与地板接触：上边不动，折痕自动置于被地板相切的位置，下边界也置于地板平面，但根据透视向摄像机平移，而且颜色采样会跟上边一致，以模仿球体的浸入效果

* 粒子完全被地板覆盖：此时效果相当于纯粹的 BillBoard
