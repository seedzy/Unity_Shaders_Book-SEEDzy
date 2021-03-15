using UnityEngine;
using UnityEditor;

public class CustomMenuExample : EditorWindow, IHasCustomMenu
{
    [MenuItem("MyWindows/Custom Menu Window Example")]
    static void ShowCustomWindow()
    {
        GetWindow<CustomMenuExample>().Show();
    }

    public void AddItemsToMenu(GenericMenu menu)
    {
        menu.AddItem(new GUIContent("Hello"), false, OnHello);
    }

    void OnHello()
    {
        Debug.Log("Hello!");
    }
}