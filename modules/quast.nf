process QUAST {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::quast=5.2.0"
    container "biocontainers/quast:5.2.0--py39pl5321h2add14b_1"

    input:
    tuple val(meta) , path(consensus)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(gff)

    output:
    tuple val(meta), path("${prefix}")                   , emit: results
    tuple val(meta), path("${prefix}.tsv")               , emit: tsv
    tuple val(meta), path("${prefix}_transcriptome.tsv") , optional: true , emit: transcriptome
    tuple val(meta), path("${prefix}_misassemblies.tsv") , optional: true , emit: misassemblies
    tuple val(meta), path("${prefix}_unaligned.tsv")     , optional: true , emit: unaligned
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args   ?: ''
    prefix        = task.ext.prefix ?: "${meta.id}"
    def features  = gff             ?  "--features $gff" : ''
    def reference = fasta           ?  "-r $fasta"       : ''
 
    """
    quast.py \\
        --output-dir $prefix \\
        $reference \\
        $features \\
        --threads $task.cpus \\
        $args \\
        ${consensus.join(' ')}

    ln -s ${prefix}/report.tsv ${prefix}.tsv
    [ -f  ${prefix}/contigs_reports/all_alignments_transcriptome.tsv ] && ln -s ${prefix}/contigs_reports/all_alignments_transcriptome.tsv ${prefix}_transcriptome.tsv
    [ -f  ${prefix}/contigs_reports/misassemblies_report.tsv         ] && ln -s ${prefix}/contigs_reports/misassemblies_report.tsv ${prefix}_misassemblies.tsv
    [ -f  ${prefix}/contigs_reports/unaligned_report.tsv             ] && ln -s ${prefix}/contigs_reports/unaligned_report.tsv ${prefix}_unaligned.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """
}
