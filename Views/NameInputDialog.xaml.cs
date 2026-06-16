using System.Windows;

namespace DesktopPet.Views;

public partial class NameInputDialog : Window
{
  public string PetName => NameTextBox.Text.Trim();

  public NameInputDialog(string currentName)
  {
    InitializeComponent();
    NameTextBox.Text = currentName;
    NameTextBox.SelectAll();
    NameTextBox.Focus();
  }

  private void OnSaveClick(object sender, RoutedEventArgs e)
  {
    if (string.IsNullOrWhiteSpace(PetName))
    {
      System.Windows.MessageBox.Show("İsim boş olamaz.", "Desktop Pet", MessageBoxButton.OK, MessageBoxImage.Information);
      return;
    }

    DialogResult = true;
    Close();
  }
}
