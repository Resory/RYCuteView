
#效果
---
![elasticDemo.gif](http://upload-images.jianshu.io/upload_images/1159720-75037fd5b6b6d002.gif?imageMogr2/auto-orient/strip)

#逻辑
---

* 下图p1,蓝色部分图形是一个CAShapeLayer,他的形状由UIBezierPath的路径组成的。

* 这个路径是由r1,r2,r3,r4,r5这5个红点确定的。其中r1,r2,r3,r4都是不动点，`唯一可以动的是r5点`。

* 根据上面的动态图可以看出,`CAShapeLayer的形状是随着r5红点的移动而相应变化的`，所以只要获得r5的坐标变化就可以用UIBezierPath做出相应的路径，然后就可以形成相应的形状。


![p1.jpg](http://upload-images.jianshu.io/upload_images/1159720-d330996503486904.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#实现
---
* ##### 初始化CAShapeLayer

```
- (void)configShapeLayer
{ 
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.fillColor = [UIColor colorWithRed:57/255.0 green:67/255.0 blue:89/255.0 alpha:1.0].CGColor;
    [self.layer addSublayer:_shapeLayer];
}
```
* ##### 初始化r5点

```
- (void)configCurveView
{
    // _curveView就是r5点
    _curveX = SYS_DEVICE_WIDTH/2.0;       // r5点x坐标
    _curveY = MIN_HEIGHT;                 // r5点y坐标
    _curveView = [[UIView alloc] initWithFrame:CGRectMake(_curveX, _curveY, 3, 3)];
    _curveView.backgroundColor = [UIColor redColor];
    [self addSubview:_curveView];
}
```
* ##### 添加移动手势&CADisplayLink

```
- (void)configAction
{
    _mHeight = 100;                       // 手势移动时相对高度
    _isAnimating = NO;                    // 是否处于动效状态

    // 手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanAction:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:pan];
    
    // calculatePath方法是算出在运行期间_curveView的坐标，从而确定_shapeLayer的形状
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(calculatePath)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    // 在手势结束的时候才调用calculatePath方法，所以一开始是暂停的
    _displayLink.paused = YES;    
}
```

* ##### 手势解析
 * 手势移动时，r5红点跟着手势移动，_shapeLayer则根据r5的坐标来扩大自己的区域 
 * 手势结束时，r5红点通过UIView的动画方法来改变r5的坐标,同时_shapeLayer根据r5的坐标缩小自己的区域并最终返回原形。

```
- (void)handlePanAction:(UIPanGestureRecognizer *)pan
{
    if(!_isAnimating)
    {
        if(pan.state == UIGestureRecognizerStateChanged)
        {
            // 手势移动时，_shapeLayer跟着手势向下扩大区域
            CGPoint point = [pan translationInView:self];
            
            // 这部分代码使r5红点跟着手势走
            _mHeight = point.y*0.7 + MIN_HEIGHT;
            _curveX = SYS_DEVICE_WIDTH/2.0 + point.x;
            _curveY = _mHeight > MIN_HEIGHT ? _mHeight : MIN_HEIGHT;
            _curveView.frame = CGRectMake(_curveX,
                                          _curveY,
                                          _curveView.frame.size.width,
                                          _curveView.frame.size.height);
            
            // 根据r5坐标,更新_shapeLayer形状
            [self updateShapeLayerPath];
            
        }
        else if (pan.state == UIGestureRecognizerStateCancelled ||
                 pan.state == UIGestureRecognizerStateEnded ||
                 pan.state == UIGestureRecognizerStateFailed)
        {
            // 手势结束时,_shapeLayer返回原状并产生弹簧动效
            _isAnimating = YES;
            _displayLink.paused = NO;           //开启displaylink,会执行方法calculatePath.
            
            // 弹簧动效
            [UIView animateWithDuration:1.0
                                  delay:0.0
                 usingSpringWithDamping:0.5
                  initialSpringVelocity:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{

                // 曲线点(r5点)是一个view.所以在block中有弹簧效果.然后根据他的动效路径,在calculatePath中计算弹性图形的形状
                _curveView.frame = CGRectMake(SYS_DEVICE_WIDTH/2.0, MIN_HEIGHT, 3, 3);
                
            } completion:^(BOOL finished) {
                
                if(finished)
                {
                    _displayLink.paused = YES;
                    _isAnimating = NO;
                }
                
            }];
        }
    }
}
```

* #####  根据r5的位置,更新_shapeLayer形状

```

- (void)updateShapeLayerPath
{
    // 更新_shapeLayer形状
    UIBezierPath *tPath = [UIBezierPath bezierPath];
    [tPath moveToPoint:CGPointMake(0, 0)];  //r1点
    [tPath addLineToPoint:CGPointMake(SYS_DEVICE_WIDTH, 0)];// r2点
    [tPath addLineToPoint:CGPointMake(SYS_DEVICE_WIDTH,  MIN_HEIGHT)]; //r4点
    [tPath addQuadCurveToPoint:CGPointMake(0, MIN_HEIGHT)
                  controlPoint:CGPointMake(_curveX, _curveY)]; // r3,r4,r5确定的一个弧线
    [tPath closePath];
    _shapeLayer.path = tPath.CGPath;
}
```
* ###### 计算弹簧效果坐标

```
- (void)calculatePath
{
    // 由于手势结束时,r5执行了一个UIView的弹簧动画,把这个过程的坐标记录下来,并相应的画出_shapeLayer形状
    CALayer *layer = _curveView.layer.presentationLayer;
    _curveX = layer.position.x;
    _curveY = layer.position.y;
    [self updateShapeLayerPath];
}
```

# 末
---
* r5点的作用非常重要，因为直接对CAShapeLayer实现动效不太好实现。所以通过对r5点实现弹簧动效，记录r5点的坐标，再用UIBezierPath形成路径，最后赋予CAShapeLayer，间接的完成了CAShapeLayer的弹簧动效。

* 如果你有疑问或者发现错误请留言给我。3Q~~
