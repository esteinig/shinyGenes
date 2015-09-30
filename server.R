library(shiny)
library(shinydashboard)
library(DT)
library(genoPlotR)
library(shinyjs)
library(seqinr)


run.prokka <- function(fasta, kingdom="Bacteria", genus="Genus", use_genus=FALSE, evalue="1e-06", project) {
  
  #  System call to Prokka generating annotation for FASTA file used in genoPlotR
  #  Default settings for Prokka, kingdom defaults to Bacteria, genus to Genus (else using genus name and genus specific DB)
  #  Fasta is row in DF
  
  fasta <- as.list(fasta)
  
  cmd <- paste('prokka', '--outdir', 'prokka','--force', '--addgenes', '--kingdom', kingdom, '--genus', genus,
               '--evalue', evalue, '--norrna', '--notrna')
  
  if (use_genus == TRUE) {
    
    cmd <- paste(cmd, '--usegenus')
    
  }
  
  cmd <- paste(cmd, fasta$datapath)
  
  system(cmd)
  
  name <- paste0(strsplit(fasta$name, "\\.")[[1]][1], '.gbk')

  prk <- file.path(getwd(), 'prokka')
  
  if (!(dir.exists(prk))){
    
    stop('\n\nProkka failed to run properly, please check your installation. Prokka can not be run from RStudio, please see the Manual.\n')
    
  }
  
  gbf <- list.files(prk, pattern='\\.gbf', full.names=T)
  cpy <- paste('cp', gbf, file.path(project, name))
 
  system(cpy)
  
  return(name)
  
}

run.blast <- function(fasta, evalue, project) {
  
  #  Runs BLAST+ with DB and BLASTN
  
  fasta_files <- as.list(fasta$datapath)
  names(fasta_files) <- fasta$name
  
  db_names <- lapply(seq(2,length(fasta_files)), function(x) { make.database(fasta_files[x], project) })
  
  for (i in seq(1, length(db_names))) {
    out_name <- file.path(project, paste(i, 'vs', i+1, '.cmp', sep=''))
    make.comparison(db_names[[i]], fasta_files[i], out_name, evalue=evalue)
  }
  
}

make.database <- function(fasta_file, project) {
  
  #  System call to generate DB from FASTA file using BLAST+ 
  
  fasta_name <- strsplit(names(fasta_file), "\\.")[[1]][1]
  dbname <- file.path(project, paste(fasta_name, '_DB', sep=''))
  
  cmd <- paste('makeblastdb', '-in', fasta_file, '-dbtype', "'nucl'", '-out', dbname)
  
  system(cmd, ignore.stdout = TRUE)
  
  return(dbname)
  
}

make.comparison <- function(db, query, out, evalue='0.001') {
  
  #  System call to BLAST+ computing BLASTN comparison given a DB and Query
  
  cmd <- paste('blastn', '-db', db, '-query', query, '-evalue', evalue, '-outfmt 7', '-out', out)
  
  system(cmd)
  
}

read.segments <- function(genbank) {
  
  message('Reading Genbank files and generating segment objects...')
  
  #  Reads Genbank files generated with Prokka or downloaded from Genbank
  #  Returns a named list (file names) of segment objects for plotting with genPlotR
  
  genbank_files <- as.list(genbank$datapath)
  
  segment_list <- lapply(genbank_files, function(x) { 
    
    seg <- read_dna_seg_from_genbank(x, gene_type='arrows')
    seg$col <- rep('black', length(seg$col))
    return(seg)
    })
  
  names(segment_list) <- genbank$name
  
  return(segment_list)
  
}

read.comparisons <- function(project, identity_filter=NULL, color_scheme='gray') {
  
  message('Reading comparisons from BLASTN (.cmp)...')
  
  #  Reads comparisons calculated with BLASTN
  #  Returns a list of comparison objects for plotting with genoPlotR
  
  files <- list.files(path=project, pattern = "\\.cmp$", full.names = TRUE)
  
  comparison_list <- lapply(files, function(x) {read_comparison_from_blast(x,filt_low_per_id=identity_filter, 
                                                                           color_scheme=color_scheme)})
  
  return(comparison_list)
  
}

make.annotations <- function(segment_list, text='gene') {
  
  message('Generating annotation objects...')
  
  #  Returns a list of annotation objects for plotting with genoPlotR
  
  annotation_list <- lapply(segment_list, function(x) {
    
    mid_pos <- middle(x)
    annotation <- annotation(x1=mid_pos, text=x[[text]])
    
  })
  
  return(annotation_list)
  
}

shinyServer(function(input, output, session) {
  
  # File Location Input
  
  getFilePaths <- function(msg=FALSE) {
    
    fasta <- input$fasta_files
    genbank <- input$genbank_files
    
    fasta <- fasta[rev(rownames(fasta)),]
    rownames(fasta) <- NULL
    
    genbank <- genbank[rev(rownames(genbank)),]
    rownames(genbank) <- NULL
    
    if (msg == TRUE){
      fasta <- subset(fasta, select= -c(3,4))
      fasta <- subset(genbank, select= -c(3,4))
    }
    
    files <- list('fasta' = fasta, 'genbank' = genbank)
    
    return(files)
    
  }
  
  output$filePaths <- renderPrint({
    
    file_info <- getFilePaths()
    
  })
  
  # Plot 
  
  updateAnnotations <- function(segment_list) {
    
    message('Updating annotation objects...')
    
    #  Returns a list of annotation objects for plotting with genoPlotR
    
    annotation_list <- lapply(segment_list, function(x) {
      
      mid_pos <- middle(x)
      annotation <- annotation(x1=mid_pos, text=x[[input$g_label_column]], col=rep(input$g_label_colour, length(x$name)),
                               rot=rep(input$g_rot, length(x$name)))
      return(annotation)
    })
    
    return(annotation_list)
    
  }
  
  
  genoPlot <- function() {
    
    if (input$g_annotations == TRUE){
      
      annotations <- updateAnnotations(results[['segments']])
      
      plot_gene_map(dna_segs=results[['segments']], comparisons=results[['comparisons']],
                    annotations=annotations, annotation_cex=input$g_label_cex, 
                    main=input$g_title, scale=input$g_scale, dna_seg_scale=input$g_scale_seg,
                    scale_cex=input$g_scale_cex, annotation_height=input$g_label_offset)
      
    } else {
      
      plot_gene_map(dna_segs=results[['segments']], comparisons=results[['comparisons']],
                    main=input$g_title, scale=input$g_scale, dna_seg_scale=input$g_scale_seg,
                    scale_cex=input$g_scale_cex, seg_plot_height=input$g_label_offset)
      
    }
    
    
    
  }
  
  makeGenePlot <- function(results) {
    
    output$genePlot <- renderPlot({
      genoPlot()
    }, height=800)
    
  }
  
  # Data Table
  
  observeEvent(input$dt_select, {
    
    makeSegmentTable()
    
  })
  
  makeSegmentTable <- function() {
    
    dt <- input$dt_select

    if (is.null(dt)){ dt <- names(results[['segments']][1])}
    
    data <- results[['segments']][[dt]]
    
    data$lty <- NULL
    data$lwd <- NULL
    data$pch <- NULL
    data$cex <- NULL
    
    output$segmentTable <- DT::renderDataTable(
    
    data, selection = list(target = 'cell')
    
  )}
  
  # Pipeline
  
  checkFiles <- function(files, project) {
    
    # Checks input files and generate missing files from Genbank with Prokka or 
    
    if (input$prokka == FALSE && length(files$genbank$name) < 2) { message('\nError. GenePlot requires two or more files (.genbank) for plotting.\n') }
    
    if (input$prokka == TRUE && length(files$fasta$name) < 2) { message('\nError. Annotation with Prokka requires two or more files (.fasta) for GenePlot.\n') }
    
    if (input$prokka == TRUE && !(is.null(files$fasta))) {
      
      gbk_names <- apply(files$fasta, 1, function(x) {

        run.prokka(x, kingdom=input$p_kingdom, genus=input$p_genus, use_genus=input$p_usegenus, evalue=input$p_evalue, project) 
        
      })
      
      unlink('prokka', recursive=T)
      
      datapaths <- sapply(gbk_names, function(x) { return(file.path(project, x)) })
      
      df <- data.frame(name=gbk_names, datapath=datapaths, stringsAsFactors = FALSE)
      rownames(df) <- seq(1, length(datapaths))
      
      files$genbank <- df
      
    }
    
    if (is.null(files$fasta)) {
      
      message('\nNo files (.fasta) detected, generating from GenBank...\n')
      
      fasta_names <- apply(files$genbank, 1, function(x) {
        x <- as.list(x)
        name <- paste0(strsplit(x$name, "\\.")[[1]][1], '.fasta')
        path <- file.path(project, name)
        gbk <- x$datapath
        gb2fasta(gbk, path)
        return(name)
        
      })
      
      datapaths <- sapply(fasta_names, function(x) { return(file.path(project, x)) })
      
      df <- data.frame(name=fasta_names, datapath=datapaths, stringsAsFactors = FALSE)
      rownames(df) <- seq(1, length(datapaths))
      
      files$fasta <- df
      
    }
    
    return(files)
    
  }
  
  runGenePlot <- function(files) {
    
    wd <- getwd()
    project = file.path(wd, 'tmp')
    unlink(project, recursive=T)
    dir.create(project)
    
    files <- checkFiles(files, project)
    
    fasta <- files[['fasta']]
    genbank <- files[['genbank']]
    
    run.blast(fasta, input$b_evalue, project)
    
    segment_list <- read.segments(genbank)
    comparison_list <- read.comparisons(project)
    annotations <- make.annotations(segment_list)
    
    results <- list('segments' = segment_list, 'comparisons' = comparison_list, 'annotations' = annotations)
    
    setwd(wd)
    
    return(results)
    
  }
  
  # Run Pipeline Button
  
  observeEvent(input$run, {
    
    withProgress(message='Running...', max=5, {
      
      files <- getFilePaths()
      
      incProgress(1)
      
      # Implement Error Check Function and Output on Settings
      
      results <<- runGenePlot(files)
      
      incProgress(1)
      
      makeGenePlot(results)
      
      incProgress(1)
      
      selections <- as.list(names(results[['segments']]))
      names(selections) <- names(results[['segments']])
      
      output$selectSegmentData <- renderUI({
        selectInput('dt_select', 'Select gene segment:', choices=selections, width='100%')
      })
      
      incProgress(1)
      
      makeSegmentTable()
      
      incProgress(1)
      
    })
    
  })
  
  # Data Table Manipulation
  
  observeEvent(input$dt_change, {
    
    value <- input$dt_new
    dt_change_mat <- input$segmentTable_cells_selected
    
    if (value != '' && nrow(dt_change_mat) != 0){
      
      data <- results[['segments']][[input$dt_select]]
  
      apply(dt_change_mat, 1, function(x){
        
        if (x[2] %in% c(2, 3, 4, 5)){
          value <- as.numeric(value)
        }
        
        data[x[1], x[2]] <<- value
        
      })
      
      results[['segments']][[input$dt_select]] <<- data
      
    }
    
    makeSegmentTable()
    makeGenePlot(results)
    
  })
  
  
  })