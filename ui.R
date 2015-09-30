library(shiny)
library(shinydashboard)
library(DT)
library(genoPlotR)
library(shinyjs)
library(seqinr)


kingdom = list(
  'Bacteria' = 'Bacteria',
  'Viruses' = 'Viruses',
  'Archaea' = 'Archaea',
  'Mitochondria' = 'Mitochondria'
)

lab = list(
  'Gene' = 'gene',
  'Name' = 'name',
  'Synonym' = 'synonym',
  'Product' = 'product'
)

shinyUI(
  dashboardPage(
    skin = 'black',
    
    dashboardHeader(title = "shinyGenes", titleWidth = 250),
    
    dashboardSidebar(width = 250, sidebarMenu(
      menuItem(" Settings", tabName = "start", icon = icon("cogs")),
      menuItem(" Data", tabName = "data", icon=icon("th-list", lib = "glyphicon")),
      menuItem(" Plot", tabName = "plot", icon=icon("bar-chart")),
      menuItem(" Manual", tabName = "manual", icon=icon("mortar-board")),
      menuItem(" About", tabName = "about", icon=icon("heart", lib = "glyphicon"))
    )),
    
    
    
    dashboardBody(
      tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")),
      tabItems(
        tabItem(tabName="start",
                fluidRow(
                  column(4, box(align='center', width='100%', status='info', h1('Pipeline'), hr(),
                                fileInput('genbank_files','GenBank', multiple=T),
                                fileInput('fasta_files', 'FASTA', multiple=T),
                                br(),
                                checkboxInput('prokka', 'Prokka Annotation'), br(),
                                actionButton('run', label='Run', width='100%', icon=icon("circle-arrow-right", lib = "glyphicon"))
                                
                                )),
                  column(4, box(align='center', width='100%', status='info', h1('Settings'), hr(),
                                h3('Prokka'), hr(),
                                selectInput('p_kingdom', 'Kingdom', selected='Bacteria', choices=kingdom),
                                br(),
                                checkboxInput('p_usegenus', 'Genus-specific DB'),
                                textInput('p_genus', 'Genus', value='Genus'),
                                br(),
                                textInput('p_evalue', 'E-value', value = '1e-06'),
                                br(),
                                h3('BLAST+'), hr(),
                                textInput('b_evalue', 'E-value', value = '1e-06'), br()
                                )),
                  column(4, box(align='center', width='100%', status='info', h1('Plot'), hr(),
                                textInput('g_title', 'Plot Title', value = 'Shiny Genes'),
                                br(), hr(),
                                checkboxInput('g_annotations', 'Annotations'), br(),
                                selectInput('g_label_column', 'Labels', selected='gene', choices=lab),
                                numericInput('g_rot', 'Rotation', value=90, min=0, max=90, step=1),
                                numericInput('g_label_cex', 'Size', value=1, min=0, max=100),
                                numericInput('g_label_offset', 'Offset', value=4, min=0, max=100),
                                colourInput('g_label_colour', 'Colour', value='#4C4C4C', showColour = 'background', palette = 'limited'),
                                br(), hr(),
                                checkboxInput('g_scale', 'Scale Bar'),
                                checkboxInput('g_scale_seg', 'Scale Segments'), br(),
                                numericInput('g_scale_cex', 'Scale Segments Size', value=1, min=1, max=100, step=1),
                                br(), hr(),
                                checkboxInput('g_cs', 'Gray Colour Scheme')))
                )
                ),
        tabItem(tabName='plot',
                fluidRow(
                  column(12, plotOutput('genePlot'))
                )),
        tabItem(tabName='data',
                fluidRow(
                  column(12, DT::dataTableOutput('segmentTable'), br(), br())),
                fluidRow(
                  column(2, box(uiOutput('selectSegmentData'), br(), width='100%')),
                  column(2, box(textInput('dt_new', 'Select cells and enter new value:', width='100%'), width='100%')), 
                  column(2, actionButton('dt_change', 'Update', icon("refresh", lib = "glyphicon"), width='100%'))
                )
                        
                         
                )
          )
      )
  )
)