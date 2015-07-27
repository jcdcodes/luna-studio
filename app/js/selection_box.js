"use strict";

var $$ = require('common');
var vs = require('shaders/select.vert')();
var fs = require('shaders/select.frag')();

var color = new THREE.Vector4(0.85, 0.55, 0.1, 0.15);

function SelectionBox() {
  var _this = this;
  var geometry = new THREE.Geometry();
  geometry.vertices.push(
    new THREE.Vector3(0,0,0),
    new THREE.Vector3(1,1,0),
    new THREE.Vector3(0,1,0),
    new THREE.Vector3(1,0,0)
  );
  geometry.faces.push(new THREE.Face3(0, 2, 1), new THREE.Face3(0, 1, 3));

  this.attributes = {
    pos: {
      type: 'v2',
      value: [
        new THREE.Vector2(-1.0, -1.0),
        new THREE.Vector2( 1.0,  1.0),
        new THREE.Vector2(-1.0,  1.0),
        new THREE.Vector2( 1.0, -1.0)
      ]
    },
  };

  this.uniforms = {
    visible: { type: 'f',  value: 0 },
    size:    { type: 'v3', value: new THREE.Vector3(0,0,1) },
    color:   { type: 'v4', value: color }
  };

  Object.keys($$.commonUniforms).forEach(function(k) {
    _this.uniforms[k] = $$.commonUniforms[k];
  });

  this.mesh = new THREE.Mesh(
      geometry,
      new THREE.ShaderMaterial( {
        uniforms:       this.uniforms,
        attributes:     this.attributes,
        vertexShader:   vs,
        fragmentShader: fs,
        transparent:    true,
        blending:       THREE.NormalBlending,
        side:           THREE.DoubleSide
    })
  );
  this.mesh.position.z = 1;
}

SelectionBox.prototype.setPos = function(x0, y0, x1, y1) {
  this.mesh.position.x = x0;
  this.mesh.position.y = y0;
  this.mesh.material.uniforms.size.value.x = x1 - x0;
  this.mesh.material.uniforms.size.value.y = y1 - y0;
};

SelectionBox.prototype.show = function() {
  this.mesh.material.uniforms.visible.value = 1;
};

SelectionBox.prototype.hide = function() {
  this.mesh.material.uniforms.visible.value = 0;
};

module.exports = SelectionBox;
