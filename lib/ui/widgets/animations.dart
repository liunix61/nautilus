import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nautilus_wallet_flutter/appstate_container.dart';

enum AnimationType {
  SEND,
  REQUEST,
  SEND_MESSAGE,
  GENERIC,
  TRANSFER_SEARCHING_QR,
  TRANSFER_SEARCHING_MANUAL,
  TRANSFER_TRANSFERRING,
  MANTA,
  REGISTER_USERNAME,
  LOADING,
  SEARCHING,
  GENERATE,
  CHANGE_REP,
}

class AnimationLoadingOverlay extends ModalRoute<void> {
  AnimationType type;
  Function onPoppedCallback;
  Color barrier;
  Color barrierStronger;
  AnimationController _controller;

  AnimationLoadingOverlay(this.type, this.barrier, this.barrierStronger, {this.onPoppedCallback});

  @override
  Duration get transitionDuration => Duration(milliseconds: 0);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor {
    if (type == AnimationType.TRANSFER_TRANSFERRING || type == AnimationType.TRANSFER_SEARCHING_QR || type == AnimationType.TRANSFER_SEARCHING_MANUAL) {
      return barrierStronger;
    }
    return barrier;
  }

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  void didComplete(void result) {
    if (this.onPoppedCallback != null) {
      this.onPoppedCallback();
    }
    super.didComplete(result);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _getAnimation(BuildContext context) {
    return SizedBox();
  }

  Widget _buildOverlayContent(BuildContext context) {
    return AppAnimation(type);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class AppAnimation extends StatefulWidget {
  AppAnimation(this.type);
  final AnimationType type;

  @override
  _AppAnimationState createState() => _AppAnimationState();

  static void animationLauncher(BuildContext context, AnimationType type, {Function onPoppedCallback}) {
    Navigator.of(context).push(
      AnimationLoadingOverlay(type, StateContainer.of(context).curTheme.animationOverlayStrong, StateContainer.of(context).curTheme.animationOverlayMedium,
          onPoppedCallback: onPoppedCallback),
    );
  }

  static String getAnimationFilePath(AnimationType type) {
    var genericLoaders = [
      "assets/animations/loading/generic_spinner_1.json",
      "assets/animations/loading/generic_spinner_2.json",
      // "assets/animations/loading/generic_spinner_3.json",
    ];

    switch (type) {
      case AnimationType.SEND:
        return "assets/animations/world-lines.json";
      case AnimationType.REQUEST:
        return "assets/animations/load-n.json";
      case AnimationType.SEND_MESSAGE:
        return "assets/animations/world-plane.json";
      case AnimationType.SEARCHING:
        return "assets/animations/searching.json";
      case AnimationType.LOADING:
        return "assets/animations/generic_spinner_1.json";
      case AnimationType.GENERIC:
        return genericLoaders[Random().nextInt(genericLoaders.length)];
      default:
        return genericLoaders[Random().nextInt(genericLoaders.length)];
    }
  }
}

class _AppAnimationState extends State<AppAnimation> with SingleTickerProviderStateMixin {
  // Invalid animation
  AnimationController _animationController;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void onAnimationLoaded(composition, Duration duration) {
    // Configure the AnimationController with the duration of the
    // Lottie file and start the animation.
    // _animationController
    //   ..duration = composition.duration
    //   ..repeat();

    _animationController
      ..duration = duration
      ..repeat();
  }

  LottieBuilder _getAnimation(BuildContext context) {
    double scalar = 0.8;
    double width = MediaQuery.of(context).size.width * scalar;
    double height = MediaQuery.of(context).size.height * scalar;

    switch (widget.type) {
      case AnimationType.SEND:
        return LottieBuilder.asset(
          AppAnimation.getAnimationFilePath(widget.type),
          controller: _animationController,
          width: width,
          height: height,
          fit: BoxFit.contain,
          onLoaded: (composition) => onAnimationLoaded(composition, Duration(milliseconds: 2000)),
        );
      case AnimationType.REQUEST:
        return LottieBuilder.asset(
          AppAnimation.getAnimationFilePath(widget.type),
          controller: _animationController,
          width: width,
          height: height,
          fit: BoxFit.contain,
          onLoaded: (composition) => onAnimationLoaded(composition, composition.duration),
        );
      case AnimationType.SEND_MESSAGE:
        return LottieBuilder.asset(
          AppAnimation.getAnimationFilePath(widget.type),
          controller: _animationController,
          width: width,
          height: height,
          fit: BoxFit.contain,
          onLoaded: (composition) => onAnimationLoaded(composition, composition.duration),
        );
      case AnimationType.SEARCHING:
        return LottieBuilder.asset(
          AppAnimation.getAnimationFilePath(widget.type),
          controller: _animationController,
          width: width,
          height: height,
          fit: BoxFit.contain,
          onLoaded: (composition) => onAnimationLoaded(composition, composition.duration),
        );
      case AnimationType.GENERIC:
        return LottieBuilder.asset(
          AppAnimation.getAnimationFilePath(widget.type),
          controller: _animationController,
          width: width,
          height: height,
          fit: BoxFit.contain,
          onLoaded: (composition) => onAnimationLoaded(composition, composition.duration),
        );
      default:
        return LottieBuilder.asset(
          AppAnimation.getAnimationFilePath(widget.type),
          controller: _animationController,
          width: width,
          height: height,
          fit: BoxFit.contain,
          onLoaded: (composition) => onAnimationLoaded(composition, composition.duration),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _getAnimation(context),
    );
  }
}
