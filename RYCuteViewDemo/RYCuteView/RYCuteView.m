//
//  shapeView.m
//  testUIBezierPath
//
//  Created by billionsfinance-resory on 15/11/2.
//  Copyright © 2015年 Resory. All rights reserved.
//

#import "RYCuteView.h"

#define SYS_DEVICE_WIDTH    ([[UIScreen mainScreen] bounds].size.width)                  // 屏幕宽度
#define SYS_DEVICE_HEIGHT   ([[UIScreen mainScreen] bounds].size.height)                 // 屏幕长度
#define MIN_HEIGHT          100                                                          // 图形最小高度

@interface RYCuteView ()

@property (nonatomic, assign) CGFloat mHeight;
@property (nonatomic, assign) CGFloat curveX;               // r5点x坐标
@property (nonatomic, assign) CGFloat curveY;               // r5点y坐标
@property (nonatomic, strong) UIView *curveView;            // r5红点
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL isAnimating;

@end

@implementation RYCuteView

static NSString *kX = @"curveX";
static NSString *kY = @"curveY";

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        [self addObserver:self forKeyPath:kX options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kY options:NSKeyValueObservingOptionNew context:nil];
        [self configShapeLayer];
        [self configCurveView];
        [self configAction];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:kX];
    [self removeObserver:self forKeyPath:kY];
}

- (void)drawRect:(CGRect)rect
{
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:kX] || [keyPath isEqualToString:kY]) {
        [self updateShapeLayerPath];
    }
}

#pragma mark -
#pragma mark - Configuration

- (void)configAction
{
    _mHeight = 100;                       // 手势移动时相对高度
    _isAnimating = NO;                    // 是否处于动效状态
    
    // 手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanAction:)];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:pan];
    
    // CADisplayLink默认每秒运行60次calculatePath是算出在运行期间_curveView的坐标，从而确定_shapeLayer的形状
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(calculatePath)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _displayLink.paused = YES;
}

- (void)configShapeLayer
{
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.fillColor = [UIColor colorWithRed:57/255.0 green:67/255.0 blue:89/255.0 alpha:1.0].CGColor;
    [self.layer addSublayer:_shapeLayer];
}

- (void)configCurveView
{
    // _curveView就是r5点
    self.curveX = SYS_DEVICE_WIDTH/2.0;       // r5点x坐标
    self.curveY = MIN_HEIGHT;                 // r5点y坐标
    _curveView = [[UIView alloc] initWithFrame:CGRectMake(_curveX, _curveY, 3, 3)];
    _curveView.backgroundColor = [UIColor redColor];
    [self addSubview:_curveView];
}

#pragma mark -
#pragma mark - Action

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
            self.curveX = SYS_DEVICE_WIDTH/2.0 + point.x;
            self.curveY = _mHeight > MIN_HEIGHT ? _mHeight : MIN_HEIGHT;
            _curveView.frame = CGRectMake(_curveX,
                                          _curveY,
                                          _curveView.frame.size.width,
                                          _curveView.frame.size.height);
        }
        else if (pan.state == UIGestureRecognizerStateCancelled ||
                 pan.state == UIGestureRecognizerStateEnded ||
                 pan.state == UIGestureRecognizerStateFailed)
        {
            // 手势结束时,_shapeLayer返回原状并产生弹簧动效
            _isAnimating = YES;
            _displayLink.paused = YES;           //开启displaylink,会执行方法calculatePath.
            /**
             首先先明确一下我的观点（kvo）方法执行的时机就是属性发生了改变才执行（就是set方法被调用才执行，_isa指针啊运行时啊我就是皮毛）我是这样理解的。
             
             我是这个意思
             我的意思是我根本不想用 [CADisplayLink displayLinkWithTarget:self selector:@selector(calculatePath)];
             用这个方法的目的不就是为了多次 当弹簧效果开始时 （小红点的 x和y改变时）self.curveY = layer.position.y;调用了set方法 observeValueForKeyPath执行
             从而调用[self updateShapeLayerPath];实现shapeView的形状改变的吗？
             
             既然根本上是view的x和y改变了（就是调用set方法才调用KVO）就执行kvo。那么我们不写CADisplayLink又如何。当view执行弹簧效果时view的x，y显然改变了，改变就该调用set方法啊。就该执行kvo啊效果应该一样啊。效果并不是我想的那样
             
             难道只有我们自己这样 self.curveX = layer.position.x; self.curveY = layer.position.y;才算调用了set方法？弹簧效果不算调set方法。

             
             
             */
            
            
            
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

- (void)updateShapeLayerPath
{
    // 更新_shapeLayer形状
    UIBezierPath *tPath = [UIBezierPath bezierPath];
    [tPath moveToPoint:CGPointMake(0, 0)];                              // r1点
    [tPath addLineToPoint:CGPointMake(SYS_DEVICE_WIDTH, 0)];            // r2点
    [tPath addLineToPoint:CGPointMake(SYS_DEVICE_WIDTH,  MIN_HEIGHT)];  // r4点
    [tPath addQuadCurveToPoint:CGPointMake(0, MIN_HEIGHT)
                  controlPoint:CGPointMake(_curveX, _curveY)]; // r3,r4,r5确定的一个弧线
    [tPath closePath];
    _shapeLayer.path = tPath.CGPath;
}


- (void)calculatePath
{
    // 由于手势结束时,r5执行了一个UIView的弹簧动画,把这个过程的坐标记录下来,并相应的画出_shapeLayer形状
    CALayer *layer = _curveView.layer.presentationLayer;
    self.curveX = layer.position.x;
    self.curveY = layer.position.y;
}

@end
