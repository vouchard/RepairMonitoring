Add-Type -AssemblyName PresentationFramework
#XAML PATH
#Write-Host "-------------------$psscriptroot"

$te = [System.TimeSpan]::new( 0,0,3)
$tmr = New-Object System.Windows.Threading.DispatcherTimer
$tmr.Interval = $te
$tmr.IsEnabled = $true
#----------MAKE USER INTERFACE
$dir_main = $psscriptroot

$comp_finder = -join($dir_main,"\componentFinder.ps1")

#--UI FILE---
$uiFile = get-content ($dir_main + "\UIxaml\MainWindow.xaml")
$subWindow_uiFile = get-content ($dir_main + "\UIxaml\Window1.xaml")
$subWindow_uiFile_repair = get-content ($dir_main + "\UIxaml\repairWindow.xaml")
$subwindow_ngRef = Get-Content ($dir_main + "\UIxaml\NG_Reference.xaml")

#-----Directories
$forRepair = $dir_main + "\ForRepair\"
$done_repair = ($dir_main +"\DoneRepair\")
$ng_ref = ($dir_main + "\NGReference\")

#files
$csv_customizableValues = Import-Csv ($dir_main + "\Params\ProdPIC.txt")
$csv_defects_txt =  ($dir_main + "\Params\defects.txt")
$csv_modelDb_txt =  ($dir_main + "\Params\modelDB.txt")



#$csv_mainGrid = Import-Csv "C:\Users\PC\Documents\control_monitoring\dataGrid1.csv"

[xml]$xaml = @"
$uiFile
"@




#$forRepair = "C:\Github\Project_inventory\ForRepair\"

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::load($reader)
$main_grid = $window.FindName("dataGrid_units")
$repair_grid = $window.FindName("dataGrid_forRepair")
$repairCount_grid = $window.FindName("dataGrid_repairCount")
$btn_add_units = $window.FindName("Add_Units")
$tb_bcd_grid = $window.FindName("textbox_bcd")
$btn_ng_ref = $window.FindName("btn_ng_ref")
$btn_finder = $window.FindName("btn_finder")

#adding buttonColumn
$button_column= New-Object System.Windows.Controls.DataGridTemplateColumn
$button_repair_columns = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
$button_repair_columns.SetValue([System.Windows.Controls.Button]::ContentProperty, "Repair")

$dataTemplate = New-Object System.Windows.DataTemplate
$dataTemplate.VisualTree = $button_repair_columns
$button_column.CellTemplate = $dataTemplate
$button_column.Width = 87
$main_grid.Columns.Add($button_column)

function get_shift_log{
$refTime1 = get-date("08:00")
$refTime2 = get-date("20:00")
$now = Get-Date

$test1 = $now -ge $refTime1
$test2 = $now -le $refTime2

if ($test1 -and $test2)
    {$filename = get-date -UFormat "%y%m%d_DS"}
    elseif($now -gt $refTime2){$filename = get-date -UFormat "%y%m%d_NS"}
    elseif($now -lt $refTime1){
            $ystrday = $now.AddDays(-1)
            $filename = Get-Date $ystrday -UFormat "%y%m%d_NS"
            }


            $filename

}

function add_to_ng_reference{
param($model,$step,$part,$rmk)
$pt = -join($ng_ref,$step,".txt")
$ln = -join($model,",",$part,",",$rmk)
$ln|Out-File $pt -Append
}


function repair_button{
    param($bcd,$id,$mdl)

[xml]$xaml_subWindow2 = @"
    $subWindow_uiFile_repair
"@
        


        $reader_subWindow2 = (New-Object System.Xml.XmlNodeReader $xaml_subWindow2)
        $window_repair = [Windows.Markup.XamlReader]::load($reader_subWindow2)
        $tb_ng_part = $window_repair.findName("textBox_NG_part")
        $tb_defect = $window_repair.findName("textBox_defect")
        $lb_defects = $window_repair.findName("listView_df")
        $btn_hti =$window_repair.findName("button_htoi")
        $btn_vis =$window_repair.findName("button_visual")
        $lb_bcd = $window_repair.findName("label")
        $tb_step = $window_repair.findName("StepNo")
        
        $window_repair.Title = $id

$lb_bcd.content = $bcd
$dftx = Get-Content $csv_defects_txt
foreach($aa in $dftx){
        $lb_defects.AddChild($aa)
    }
#$tb_ng_part.Background = "
$tb_ng_part.text = ""



$lb_defects.add_selectionchanged({
    $tb_defect.Text = $lb_defects.SelectedItem
    $tb_ng_part.Background = "Red"
    
    $tb_ng_part.Focus()

})

$btn_hti.add_click({
$line = -join((Get-Date).ToString(),",",$lb_bcd.content,",",$tb_ng_part.text,",",$tb_defect.text,",",$tb_step.text)
$fname = -join($done_repair,(get_shift_log),".txt")

$ln2 = -join($line.ToString(),",","hard to repair")
$ln2|Out-File $fname -Append
$root_file = $forRepair + $window_repair.Title + ".txt"
Remove-Item $root_file
add_item_main_grid
add_to_ng_reference -model $mdl -step $tb_step.text -part $tb_ng_part.text -rmk "Hard to Investigate"


$window_repair.close()

})

$btn_vis.add_click({
$line = -join((Get-Date).ToString(),",",$lb_bcd.content,",",$tb_ng_part.text,",",$tb_defect.text,",",$tb_step.text)
$fname = -join($done_repair,(get_shift_log),".txt")

$ln2 = -join($line.ToString(),",","Visual NG")
$ln2|Out-File $fname -Append
$root_file = $forRepair + $window_repair.Title + ".txt"
Remove-Item $root_file
add_item_main_grid
add_to_ng_reference -model $mdl -step $tb_step.text -part $tb_ng_part.text -rmk "Visual"

$window_repair.close()
})







$window_repair.ShowDialog()

}

[System.Windows.RoutedEventHandler]$clickEvent = {
    param($s,$e)
    #write-host $main_grid.SelectedItems.EndorsedBy
    repair_button -bcd ($main_grid.SelectedItems.Barcode) -id ($main_grid.SelectedItems.ID) -mdl ($main_grid.SelectedItems.Model)
}
$button_repair_columns.AddHandler([System.Windows.Controls.Button]::ClickEvent,$clickEvent)
function add_item_main_grid{
param($tx)
    #$main_grid.Clear()
    $rp = Get-ChildItem $forRepair
    $fl = @()
    foreach($aa in $rp){
        $oneFile = Import-Csv $aa.fullname -Header "DateEndorsed","Endorsedby","Barcode","ID","Model"
        $pref = -join(($onefile.barcode)[0..2])
        $oneFile[0].model = (Import-Csv $csv_modelDb_txt|Where-Object{$_.Prefix -eq $pref}).Model 
#        $oneFile|Add-Member -MemberType ScriptProperty -name "Model" -Value {(Import-Csv $csv_modelDb_txt|Where-Object{$_.Prefix -eq (-join(($this.barcode)[0..2]))}).Model}
      
        $fl += $oneFile    
    }
    if ($null -ne $tx){$fl = ($fl|Where-Object {$_.barcode -match $tx})}
    $main_grid.Items.clear()


    foreach($gg in $fl){
    $main_grid.AddChild($gg)

    }
    






}
    
function add_unit_window{
    param($csvPath)

[xml]$xaml_subWindow1 = @"
    $subWindow_uiFile
"@
        


        $reader_subWindow1 = (New-Object System.Xml.XmlNodeReader $xaml_subWindow1)
        $window_add_Item = [Windows.Markup.XamlReader]::load($reader_subWindow1)
        $cb_pic = $window_add_Item.findName("cb_pic")
        $tb_bcd = $window_add_Item.findName("tb_bcd")
        $tb_bcd.text = ""
        foreach ($aa in $csv_customizableValues){
            $cb_pic.items.add($aa.prod_pic)

        }

        $tb_bcd.add_textchanged({
            if (($tb_bcd.text).length -gt 9){
                if ($null -ne $cb_pic.selecteditem){
                $dt = get-date -uformat %y%m%d%H%S
                $line = -join((Get-Date).ToString(),",",$cb_pic.selecteditem,",",$tb_bcd.text,",",$dt)
                $dt = -join($forRepair,$dt,".txt")
                $line|Out-File -FilePath $dt
                $tb_bcd.text = ""
                add_item_main_grid
                }else{
                    [System.Windows.MessageBox]::Show("Incomplete Details")
                    $tb_bcd.text = ""
                    }
            }
            })
$window_add_Item.ShowDialog()

}

function ng_ref_window{
[xml]$xaml_subWindow1 = @"
    $subwindow_ngRef
"@

        $reader_subWindow1 = (New-Object System.Xml.XmlNodeReader $xaml_subWindow1)
        $window_ref = [Windows.Markup.XamlReader]::load($reader_subWindow1)
        $tb_step = $window_ref.findName("textBox")
        $dgrid = $window_ref.findName("dataGrid")


        



        $tb_step.add_textchanged({
            $pt = -join($ng_ref,$tb_step.text,".txt")
            $test = Test-Path $pt
  
            $dgrid.items.clear()
            if($test){
                $dt = Import-Csv $pt -Header "MODEL","NG_PART","NG_TYPE"
                
                foreach($gg in $dt){
               # Wait-Debugger
                $dgrid.AddChild($gg)
                }


            }

        })






        $window_ref.showdialog()











}




#mainWindow_Events


$btn_add_units.add_click({add_unit_window -csvPath $csv_mainGrid})
$tb_bcd_grid.add_textchanged({
        $tmr.ToStop()
        add_item_main_grid -tx $tb_bcd_grid.Text
        $tmr.ToStart()
        




    })
$btn_ng_ref.add_click({ng_ref_window})
$btn_finder.add_Click({
powershell.exe -file $comp_finder

})




$tmr.add_tick({add_item_main_grid})
$tmr.Start()
$window.showDialog()


