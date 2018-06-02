(function(exports) {
	var invalidParamStr = 'Invalid parameter';
	var missingParamStr = 'Missing parameter';

	// app id
	YRAppId = [NSBundle mainBundle].bundleIdentifier;

	// mainBundlePath
	YRAppBundlePath = [NSBundle mainBundle].bundlePath;

	// document path
	YRAppDocmentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

	// caches path
	YRAppCachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]; 

	// 通过系统动态库的名字 加载系统动态库
	YRAppLoadFramework = function(name) {
		var head = "/System/Library/";
		var foot = "Frameworks/" + name + ".framework";
		var bundle = [NSBundle bundleWithPath:head + foot] || [NSBundle bundleWithPath:head + "Private" + foot];
  		[bundle load];
  		return bundle;
	};

	// keyWindow
	YRAppKeyWindow = function() {
		return UIApp.keyWindow;
	};

	// 根控制器
	YRAppRootVc =  function() {
		return UIApp.keyWindow.rootViewController;
	};

	//内部方法			 找到显示在最前面的控制器
	var _YRFrontVc = function(vc) {
		if (vc.presentedViewController) {
        	return _YRFrontVc(vc.presentedViewController);
	    }else if ([vc isKindOfClass:[UITabBarController class]]) {
	        return _YRFrontVc(vc.selectedViewController);
	    } else if ([vc isKindOfClass:[UINavigationController class]]) {
	        return _YRFrontVc(vc.visibleViewController);
	    } else {
	    	var count = vc.childViewControllers.count;
    		for (var i = count - 1; i >= 0; i--) {
    			var childVc = vc.childViewControllers[i];
    			if (childVc && childVc.view.window) {
    				vc = _YRFrontVc(childVc);
    				break;
    			}
    		}
	        return vc;
    	}
	};

	YRAppFrontVc =  function() {
		return _YRFrontVc(UIApp.keyWindow.rootViewController);
	};

	// CG函数
	YRAppPointMake = function(x, y) { 
		return {0 : x, 1 : y}; 
	};

	YRAppSizeMake = function(w, h) { 
		return {0 : w, 1 : h}; 
	};

	YRAppRectMake = function(x, y, w, h) { 
		return {0 : YRAppPointMake(x, y), 1 : YRAppSizeMake(w, h)}; 
	};

	// 递归打印controller的层级结构
	YRAppChildVcs = function(vc) {
		if (![vc isKindOfClass:[UIViewController class]]) throw new Error(invalidParamStr);
		return [vc _printHierarchy].toString();
	};

	// 递归打印view的层级结构
	YRAppSubviews = function(view) { 
		if (![view isKindOfClass:[UIView class]]) throw new Error(invalidParamStr);
		return view.recursiveDescription().toString(); 
	};

	// 判断是否为字符串 "str" @"str"
	YRAppIsString = function(str) {
		return typeof str == 'string' || str instanceof String;
	};

	// 判断是否为数组 []、@[]
	YRAppIsArray = function(arr) {
		return arr instanceof Array;
	};

	// 判断是否为数字 666 @666
	YRAppIsNumber = function(num) {
		return typeof num == 'number' || num instanceof Number;
	};

	//内部方法    	根据字符串获取对应的类
	var _YRClass = function(className) {
		if (!className) throw new Error(missingParamStr);
		if (YRIsString(className)) {
			return NSClassFromString(className);
		} 
		if (!className) throw new Error(invalidParamStr);
		// 对象或者类
		return className.class();
	};

	// 给一个类和 和一个正则 打印出所有的子类 	
	YRAppSubclasses = function(className, reg) {
		className = _YRClass(className);

		return [c for each (c in ObjectiveC.classes) 
		if (c != className 
			&& class_getSuperclass(c) 
			&& [c isSubclassOfClass:className] 
			&& (!reg || reg.test(c)))
			];
	};

	// 内部方法				 打印所有的方法
	var _YRGetMethods = function(className, reg, clazz) {
		className = _YClass(className);

		var count = new new Type('I');
		var classObj = clazz ? className.constructor : className;
		var methodList = class_copyMethodList(classObj, count);
		var methodsArray = [];
		var methodNamesArray = [];
		for(var i = 0; i < *count; i++) {
			var method = methodList[i];
			var selector = method_getName(method);
			var name = sel_getName(selector);
			if (reg && !reg.test(name)) continue;
			methodsArray.push({
				selector : selector, 
				type : method_getTypeEncoding(method)
			});
			methodNamesArray.push(name);
		}
		free(methodList);
		return [methodsArray, methodNamesArray];
	};
	// 内部方法 
	var _YRMethods = function(className, reg, clazz) {
		return _YRGetMethods(className, reg, clazz)[0];
	};

	// 内部方法 		打印所有的方法名字
	var _YRMethodNames = function(className, reg, clazz) {
		return _YRGetMethods(className, reg, clazz)[1];
	};

	// 根据类名 和 正则 打印出所有的实例方法		
	YRAppInstanceMethods = function(className, reg) {
		return _YRMethods(className, reg);
	};

	// 根据类名 和 正则 打印出所有的实例方法	  的名称	
	YRAppInstanceMethodNames = function(className, reg) {
		return _YRMethodNames(className, reg);
	};

	// 打印所有的类方法
	YRAppClassMethods = function(className, reg) {
		return _YRMethods(className, reg, true);
	};

	// 根据类名 和 正则 打印出所有的 类 方法	名称
	YRAppClassMethodNames = function(className, reg) {
		return _YRMethodNames(className, reg, true);
	};

	// 打印所有的成员变量
	YRAppIvars = function(obj, reg){ 
		if (!obj) throw new Error(missingParamStr);
		var x = {}; 
		for(var i in *obj) { 
			try { 
				var value = (*obj)[i];
				if (reg && !reg.test(i) && !reg.test(value)) continue;
				x[i] = value; 
			} catch(e){} 
		} 
		return x; 
	};

	// 打印所有的成员变量名字
	YRAppIvarNames = function(obj, reg) {
		if (!obj) throw new Error(missingParamStr);
		var array = [];
		for(var name in *obj) { 
			if (reg && !reg.test(name)) continue;
			array.push(name);
		}
		return array;
	};
})(exports);




// 获取AppID         				--> YRAppID
// 获取App Bundle 路劲				--> YRAppBundlePath
// 获取App caches 路劲				--> YRAppCachePath
// 获取App docment 路劲				--> YRAppDocmentPath
	
// 给 App 加载动态库					--> YRLoadFramework(MKMapKit)

// 获取App 当前keyWindow 			--> YRAppKeyWindow()
// 获取App 当前的RootViewcontroller	--> YRAppRootVc()
// 获取App 当前最前面的控制器			--> YRAppFrontVc()

// 创建一个point						--> YRAppPointMake(10,20)
// 创建一个size						--> YRAppSizeMake(10,20)
// 创建一个rect						--> YRAppRectMake(10,10,10,10)

// 获取 某个控制器的所有子控制器		--> YRAppChildVcs(loginVc)
// 获取某个view 的所有子View			--> YRAppSubViews(redView)

// 判断一个变量是否是一个字符串			--> YRAppIdString(abc)
// 判断一个变量是否是一个数组			--> YRAppIsArray(arr)
// 判断一个变量是否是一个数字			--> YRAppIsNumber(num)

// 获取某个类的所有子类  正则匹配		--> YRAppSubClasses([UIView class], /login/)

// 获取某个类的所有类方法				--> YRAppInstanceMethods([UIView class], /login/)
// 获取某个类的所有类方法 的名字		--> YRAppInstanceMethodNames([UIView class],/login/)

// 获取某个类的所有的 对象方法			--> YRAppClassMethods([UIView class], /login/)
// 获取某个类的所有的 对象方法 的名字	--> YRAppClassMethodNames([UIView class], /login/)

// 获取某个类的所有成员变量  正则匹配   --> YRAppIvars(obj,/reg/)

// 获取某个类的所有成员变量的名字  正则匹配 --> YRAppIvarNames(obj,/reg/)










