using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ColorPicker : MonoBehaviour
{
    public BoxCollider pickerCollider;

    private bool _grab;
    private Camera _camera;
    private Texture2D _screenRenderTexture;
    private static Texture2D _staticRectTexture;
    private static GUIStyle _staticRectStyle;
    
    private Vector3 _PixelPosition = Vector3.zero;
    private Color _pickedColor = Color.white;
    private void Awake()
    {
        _camera = GetComponent<Camera>();
        if (_camera == null)
        {
            Debug.LogError("ColorPicker需要一个Camera!");
            return;
        }

        if (pickerCollider == null)
        {
            pickerCollider = gameObject.AddComponent<BoxCollider>();
            pickerCollider.center = Vector3.zero;
            pickerCollider.center += _camera.transform.worldToLocalMatrix.MultiplyVector(_camera.transform.forward) *
                                     (_camera.nearClipPlane + 0.2f);
            pickerCollider.size = new Vector3(Screen.width,Screen.height,0.1f);
        }
    }

    private void OnPostRender()
    {
        if (_grab)
        {
            _screenRenderTexture = new Texture2D(Screen.width, Screen.height);
            _screenRenderTexture.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0);
            _screenRenderTexture.Apply();
            _pickedColor =
                _screenRenderTexture.GetPixel(Mathf.FloorToInt(_PixelPosition.x), Mathf.FloorToInt(_PixelPosition.y));
            _grab = false;
        }
    }

    private void OnMouseDown()
    {
        _grab = true;
        _PixelPosition = Input.mousePosition;
    }

    private void OnGUI()
    {
        GUI.Box(new Rect(0,0,120,200),"Color Picker" );
        GUIDrawRect(new Rect(20,30,80,80),_pickedColor );
        GUI.Label(new Rect(10, 120, 100, 20),
            "R: " + Math.Round((double) _pickedColor.r, 4) + "\t(" + Mathf.FloorToInt(_pickedColor.r * 255) + ")");
        GUI.Label(new Rect(10, 140, 100, 20),
            "G: " + Math.Round((double) _pickedColor.g, 4) + "\t(" + Mathf.FloorToInt(_pickedColor.g * 255) + ")");
        GUI.Label(new Rect(10, 160, 100, 20),
            "B: " + Math.Round((double) _pickedColor.b, 4) + "\t(" + Mathf.FloorToInt(_pickedColor.b * 255) + ")");
        GUI.Label(new Rect(10, 180, 100, 20),
            "A: " + Math.Round((double) _pickedColor.a, 4) + "\t(" + Mathf.FloorToInt(_pickedColor.a * 255) + ")");
    }

    public static void GUIDrawRect(Rect position,Color color)
    {
        if (_staticRectTexture == null)
        {
            _staticRectTexture = new Texture2D(1,1);
        }

        if (_staticRectStyle == null)
        {
            _staticRectStyle = new GUIStyle();
        }
        
        _staticRectTexture.SetPixel(0,0,color);
        _staticRectTexture.Apply();

        _staticRectStyle.normal.background = _staticRectTexture;
        GUI.Box(position,GUIContent.none,_staticRectStyle);
    }
}
