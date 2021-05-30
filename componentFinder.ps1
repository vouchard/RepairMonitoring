
#loading assemblies
add-type -AssemblyName system.windows.forms
add-type -AssemblyName system.drawing

# Default Variables
$df = $PSScriptRoot
$masterpath = (-join($df,"\componentFinder"))
$upperMargin = 3
$modelpath = Get-ChildItem "$masterpath\model_db\"
$src = ($modelpath[0]).FullName

# UI Objects
$form = New-Object System.Windows.Forms.Form
$form.Size = '1000,768'
$form.Text = "Component Finder - Trial"
$form.BackColor = "White"

$tb_part = New-Object System.Windows.Forms.TextBox
$tb_part.Location = '150,30'


$drp_files = New-Object System.Windows.Forms.ComboBox
$drp_files.Location = '10,30'
foreach($aa in $modelpath){$drp_files.Items.Add($aa.baseName)|Out-Null}

$btn_find = New-Object System.Windows.Forms.Button
$btn_find.Location = '250,28'
$btn_find.Text = "FIND"


# Graphic Objects
$brush = New-Object System.Drawing.SolidBrush green
$pen = New-Object System.Drawing.Pen black
$formgraphics = $form.CreateGraphics()







#Functions
function reset_points{
    param($src)
    $src = Import-Csv $src


        foreach($aa in $src)
            {
                $brush.Color = "green"
                $x = [math]::Ceiling($aa.x) * $upperMargin
                $y = ([math]::Ceiling($aa.y) * $upperMargin) + 100


                $part_body = New-Object System.Drawing.Rectangle $x,$y,4,4
                #$formgraphics.DrawRectangle($pen,$part_body)
                #$formgraphics.FillRectangle($brush,$part_body)
                 $formgraphics.FillEllipse($brush,$part_body)
#                $formgraphics.DrawEllipse($pen,$part_body)

        }

}

function set_point{
param($locx,$locy)
          $brush.Color = "rED"
          $x = [math]::Ceiling($locx) * $upperMargin
          $y = ([math]::Ceiling($locy) * $upperMargin) + 100

          #$cx = [math]::Ceiling($locx) - 5
         # $cx = [math]::Ceiling($locy) - 5

          $part_body = New-Object System.Drawing.Rectangle $x,$y,5,5 
          $formgraphics.DrawEllipse($pen,$part_body)
          $formgraphics.FillEllipse($brush,$part_body)
          $pen.DashStyle = "Dash"
          $formgraphics.drawLine($pen,$x,$y,0,$y)
          $formgraphics.drawLine($pen,$x,$y,$x,100)
   
}


#events



#$form.add_shown({reset_points -src $src})


$drp_files.add_selectedValueChanged({
$formgraphics.Clear("White")
reset_points -src (-join($masterpath,"\model_db\",$drp_files.Text,".csv"))
})
$btn_find.add_click({
$src = (-join($masterpath,"\model_db\",$drp_files.Text,".csv"))
$inCSV = Import-Csv $src |Where-Object {$_.location -eq $tb_part.Text}

foreach($asd in $inCSV){
    set_point -locx $asd.x -locy $asd.y

}
})





$form.Controls.Add($tb_part)
$form.Controls.Add($drp_files)
$form.Controls.Add($btn_find)
$form.ShowDialog()