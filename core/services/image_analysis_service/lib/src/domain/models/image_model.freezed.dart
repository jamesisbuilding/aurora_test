// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImageModel {

 String get uid; String get title; String get description; bool get isFavourite; String get url; List<Color> get colorPalette; String get localPath; Uint8List? get byteList; String get pixelSignature;// New fields corresponding to GPT image pipeline
 String get founderName; String get founderDescription; String get description2; String get hypeBuildingTagline1; String get hypeBuildingTagline2; String get hypeBuildingTagline3; String get hypeBuildingTagline4; String get hypeBuildingTagline5;
/// Create a copy of ImageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageModelCopyWith<ImageModel> get copyWith => _$ImageModelCopyWithImpl<ImageModel>(this as ImageModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.colorPalette, colorPalette)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&const DeepCollectionEquality().equals(other.byteList, byteList)&&(identical(other.pixelSignature, pixelSignature) || other.pixelSignature == pixelSignature)&&(identical(other.founderName, founderName) || other.founderName == founderName)&&(identical(other.founderDescription, founderDescription) || other.founderDescription == founderDescription)&&(identical(other.description2, description2) || other.description2 == description2)&&(identical(other.hypeBuildingTagline1, hypeBuildingTagline1) || other.hypeBuildingTagline1 == hypeBuildingTagline1)&&(identical(other.hypeBuildingTagline2, hypeBuildingTagline2) || other.hypeBuildingTagline2 == hypeBuildingTagline2)&&(identical(other.hypeBuildingTagline3, hypeBuildingTagline3) || other.hypeBuildingTagline3 == hypeBuildingTagline3)&&(identical(other.hypeBuildingTagline4, hypeBuildingTagline4) || other.hypeBuildingTagline4 == hypeBuildingTagline4)&&(identical(other.hypeBuildingTagline5, hypeBuildingTagline5) || other.hypeBuildingTagline5 == hypeBuildingTagline5));
}


@override
int get hashCode => Object.hash(runtimeType,uid,title,description,isFavourite,url,const DeepCollectionEquality().hash(colorPalette),localPath,const DeepCollectionEquality().hash(byteList),pixelSignature,founderName,founderDescription,description2,hypeBuildingTagline1,hypeBuildingTagline2,hypeBuildingTagline3,hypeBuildingTagline4,hypeBuildingTagline5);

@override
String toString() {
  return 'ImageModel(uid: $uid, title: $title, description: $description, isFavourite: $isFavourite, url: $url, colorPalette: $colorPalette, localPath: $localPath, byteList: $byteList, pixelSignature: $pixelSignature, founderName: $founderName, founderDescription: $founderDescription, description2: $description2, hypeBuildingTagline1: $hypeBuildingTagline1, hypeBuildingTagline2: $hypeBuildingTagline2, hypeBuildingTagline3: $hypeBuildingTagline3, hypeBuildingTagline4: $hypeBuildingTagline4, hypeBuildingTagline5: $hypeBuildingTagline5)';
}


}

/// @nodoc
abstract mixin class $ImageModelCopyWith<$Res>  {
  factory $ImageModelCopyWith(ImageModel value, $Res Function(ImageModel) _then) = _$ImageModelCopyWithImpl;
@useResult
$Res call({
 String uid, String title, String description, bool isFavourite, String url, List<Color> colorPalette, String localPath, Uint8List? byteList, String pixelSignature, String founderName, String founderDescription, String description2, String hypeBuildingTagline1, String hypeBuildingTagline2, String hypeBuildingTagline3, String hypeBuildingTagline4, String hypeBuildingTagline5
});




}
/// @nodoc
class _$ImageModelCopyWithImpl<$Res>
    implements $ImageModelCopyWith<$Res> {
  _$ImageModelCopyWithImpl(this._self, this._then);

  final ImageModel _self;
  final $Res Function(ImageModel) _then;

/// Create a copy of ImageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? title = null,Object? description = null,Object? isFavourite = null,Object? url = null,Object? colorPalette = null,Object? localPath = null,Object? byteList = freezed,Object? pixelSignature = null,Object? founderName = null,Object? founderDescription = null,Object? description2 = null,Object? hypeBuildingTagline1 = null,Object? hypeBuildingTagline2 = null,Object? hypeBuildingTagline3 = null,Object? hypeBuildingTagline4 = null,Object? hypeBuildingTagline5 = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,colorPalette: null == colorPalette ? _self.colorPalette : colorPalette // ignore: cast_nullable_to_non_nullable
as List<Color>,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,byteList: freezed == byteList ? _self.byteList : byteList // ignore: cast_nullable_to_non_nullable
as Uint8List?,pixelSignature: null == pixelSignature ? _self.pixelSignature : pixelSignature // ignore: cast_nullable_to_non_nullable
as String,founderName: null == founderName ? _self.founderName : founderName // ignore: cast_nullable_to_non_nullable
as String,founderDescription: null == founderDescription ? _self.founderDescription : founderDescription // ignore: cast_nullable_to_non_nullable
as String,description2: null == description2 ? _self.description2 : description2 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline1: null == hypeBuildingTagline1 ? _self.hypeBuildingTagline1 : hypeBuildingTagline1 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline2: null == hypeBuildingTagline2 ? _self.hypeBuildingTagline2 : hypeBuildingTagline2 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline3: null == hypeBuildingTagline3 ? _self.hypeBuildingTagline3 : hypeBuildingTagline3 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline4: null == hypeBuildingTagline4 ? _self.hypeBuildingTagline4 : hypeBuildingTagline4 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline5: null == hypeBuildingTagline5 ? _self.hypeBuildingTagline5 : hypeBuildingTagline5 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageModel].
extension ImageModelPatterns on ImageModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageModel value)  $default,){
final _that = this;
switch (_that) {
case _ImageModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageModel value)?  $default,){
final _that = this;
switch (_that) {
case _ImageModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String title,  String description,  bool isFavourite,  String url,  List<Color> colorPalette,  String localPath,  Uint8List? byteList,  String pixelSignature,  String founderName,  String founderDescription,  String description2,  String hypeBuildingTagline1,  String hypeBuildingTagline2,  String hypeBuildingTagline3,  String hypeBuildingTagline4,  String hypeBuildingTagline5)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageModel() when $default != null:
return $default(_that.uid,_that.title,_that.description,_that.isFavourite,_that.url,_that.colorPalette,_that.localPath,_that.byteList,_that.pixelSignature,_that.founderName,_that.founderDescription,_that.description2,_that.hypeBuildingTagline1,_that.hypeBuildingTagline2,_that.hypeBuildingTagline3,_that.hypeBuildingTagline4,_that.hypeBuildingTagline5);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String title,  String description,  bool isFavourite,  String url,  List<Color> colorPalette,  String localPath,  Uint8List? byteList,  String pixelSignature,  String founderName,  String founderDescription,  String description2,  String hypeBuildingTagline1,  String hypeBuildingTagline2,  String hypeBuildingTagline3,  String hypeBuildingTagline4,  String hypeBuildingTagline5)  $default,) {final _that = this;
switch (_that) {
case _ImageModel():
return $default(_that.uid,_that.title,_that.description,_that.isFavourite,_that.url,_that.colorPalette,_that.localPath,_that.byteList,_that.pixelSignature,_that.founderName,_that.founderDescription,_that.description2,_that.hypeBuildingTagline1,_that.hypeBuildingTagline2,_that.hypeBuildingTagline3,_that.hypeBuildingTagline4,_that.hypeBuildingTagline5);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String title,  String description,  bool isFavourite,  String url,  List<Color> colorPalette,  String localPath,  Uint8List? byteList,  String pixelSignature,  String founderName,  String founderDescription,  String description2,  String hypeBuildingTagline1,  String hypeBuildingTagline2,  String hypeBuildingTagline3,  String hypeBuildingTagline4,  String hypeBuildingTagline5)?  $default,) {final _that = this;
switch (_that) {
case _ImageModel() when $default != null:
return $default(_that.uid,_that.title,_that.description,_that.isFavourite,_that.url,_that.colorPalette,_that.localPath,_that.byteList,_that.pixelSignature,_that.founderName,_that.founderDescription,_that.description2,_that.hypeBuildingTagline1,_that.hypeBuildingTagline2,_that.hypeBuildingTagline3,_that.hypeBuildingTagline4,_that.hypeBuildingTagline5);case _:
  return null;

}
}

}

/// @nodoc


class _ImageModel extends ImageModel {
  const _ImageModel({required this.uid, required this.title, required this.description, required this.isFavourite, required this.url, required final  List<Color> colorPalette, required this.localPath, this.byteList, required this.pixelSignature, required this.founderName, required this.founderDescription, required this.description2, required this.hypeBuildingTagline1, required this.hypeBuildingTagline2, required this.hypeBuildingTagline3, required this.hypeBuildingTagline4, required this.hypeBuildingTagline5}): _colorPalette = colorPalette,super._();
  

@override final  String uid;
@override final  String title;
@override final  String description;
@override final  bool isFavourite;
@override final  String url;
 final  List<Color> _colorPalette;
@override List<Color> get colorPalette {
  if (_colorPalette is EqualUnmodifiableListView) return _colorPalette;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colorPalette);
}

@override final  String localPath;
@override final  Uint8List? byteList;
@override final  String pixelSignature;
// New fields corresponding to GPT image pipeline
@override final  String founderName;
@override final  String founderDescription;
@override final  String description2;
@override final  String hypeBuildingTagline1;
@override final  String hypeBuildingTagline2;
@override final  String hypeBuildingTagline3;
@override final  String hypeBuildingTagline4;
@override final  String hypeBuildingTagline5;

/// Create a copy of ImageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageModelCopyWith<_ImageModel> get copyWith => __$ImageModelCopyWithImpl<_ImageModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other._colorPalette, _colorPalette)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&const DeepCollectionEquality().equals(other.byteList, byteList)&&(identical(other.pixelSignature, pixelSignature) || other.pixelSignature == pixelSignature)&&(identical(other.founderName, founderName) || other.founderName == founderName)&&(identical(other.founderDescription, founderDescription) || other.founderDescription == founderDescription)&&(identical(other.description2, description2) || other.description2 == description2)&&(identical(other.hypeBuildingTagline1, hypeBuildingTagline1) || other.hypeBuildingTagline1 == hypeBuildingTagline1)&&(identical(other.hypeBuildingTagline2, hypeBuildingTagline2) || other.hypeBuildingTagline2 == hypeBuildingTagline2)&&(identical(other.hypeBuildingTagline3, hypeBuildingTagline3) || other.hypeBuildingTagline3 == hypeBuildingTagline3)&&(identical(other.hypeBuildingTagline4, hypeBuildingTagline4) || other.hypeBuildingTagline4 == hypeBuildingTagline4)&&(identical(other.hypeBuildingTagline5, hypeBuildingTagline5) || other.hypeBuildingTagline5 == hypeBuildingTagline5));
}


@override
int get hashCode => Object.hash(runtimeType,uid,title,description,isFavourite,url,const DeepCollectionEquality().hash(_colorPalette),localPath,const DeepCollectionEquality().hash(byteList),pixelSignature,founderName,founderDescription,description2,hypeBuildingTagline1,hypeBuildingTagline2,hypeBuildingTagline3,hypeBuildingTagline4,hypeBuildingTagline5);

@override
String toString() {
  return 'ImageModel(uid: $uid, title: $title, description: $description, isFavourite: $isFavourite, url: $url, colorPalette: $colorPalette, localPath: $localPath, byteList: $byteList, pixelSignature: $pixelSignature, founderName: $founderName, founderDescription: $founderDescription, description2: $description2, hypeBuildingTagline1: $hypeBuildingTagline1, hypeBuildingTagline2: $hypeBuildingTagline2, hypeBuildingTagline3: $hypeBuildingTagline3, hypeBuildingTagline4: $hypeBuildingTagline4, hypeBuildingTagline5: $hypeBuildingTagline5)';
}


}

/// @nodoc
abstract mixin class _$ImageModelCopyWith<$Res> implements $ImageModelCopyWith<$Res> {
  factory _$ImageModelCopyWith(_ImageModel value, $Res Function(_ImageModel) _then) = __$ImageModelCopyWithImpl;
@override @useResult
$Res call({
 String uid, String title, String description, bool isFavourite, String url, List<Color> colorPalette, String localPath, Uint8List? byteList, String pixelSignature, String founderName, String founderDescription, String description2, String hypeBuildingTagline1, String hypeBuildingTagline2, String hypeBuildingTagline3, String hypeBuildingTagline4, String hypeBuildingTagline5
});




}
/// @nodoc
class __$ImageModelCopyWithImpl<$Res>
    implements _$ImageModelCopyWith<$Res> {
  __$ImageModelCopyWithImpl(this._self, this._then);

  final _ImageModel _self;
  final $Res Function(_ImageModel) _then;

/// Create a copy of ImageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? title = null,Object? description = null,Object? isFavourite = null,Object? url = null,Object? colorPalette = null,Object? localPath = null,Object? byteList = freezed,Object? pixelSignature = null,Object? founderName = null,Object? founderDescription = null,Object? description2 = null,Object? hypeBuildingTagline1 = null,Object? hypeBuildingTagline2 = null,Object? hypeBuildingTagline3 = null,Object? hypeBuildingTagline4 = null,Object? hypeBuildingTagline5 = null,}) {
  return _then(_ImageModel(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,colorPalette: null == colorPalette ? _self._colorPalette : colorPalette // ignore: cast_nullable_to_non_nullable
as List<Color>,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,byteList: freezed == byteList ? _self.byteList : byteList // ignore: cast_nullable_to_non_nullable
as Uint8List?,pixelSignature: null == pixelSignature ? _self.pixelSignature : pixelSignature // ignore: cast_nullable_to_non_nullable
as String,founderName: null == founderName ? _self.founderName : founderName // ignore: cast_nullable_to_non_nullable
as String,founderDescription: null == founderDescription ? _self.founderDescription : founderDescription // ignore: cast_nullable_to_non_nullable
as String,description2: null == description2 ? _self.description2 : description2 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline1: null == hypeBuildingTagline1 ? _self.hypeBuildingTagline1 : hypeBuildingTagline1 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline2: null == hypeBuildingTagline2 ? _self.hypeBuildingTagline2 : hypeBuildingTagline2 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline3: null == hypeBuildingTagline3 ? _self.hypeBuildingTagline3 : hypeBuildingTagline3 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline4: null == hypeBuildingTagline4 ? _self.hypeBuildingTagline4 : hypeBuildingTagline4 // ignore: cast_nullable_to_non_nullable
as String,hypeBuildingTagline5: null == hypeBuildingTagline5 ? _self.hypeBuildingTagline5 : hypeBuildingTagline5 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
