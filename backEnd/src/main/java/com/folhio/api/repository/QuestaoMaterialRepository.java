package com.folhio.api.repository;

import com.folhio.api.entity.QuestaoMaterial;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface QuestaoMaterialRepository extends JpaRepository<QuestaoMaterial, String> {

    @Query("""
            select q from MaterialQuestion q
            where q.active = true
              and (:discipline is null or q.discipline = :discipline)
              and (:subject is null or q.subject = :subject)
              and (:schoolYear is null or q.schoolYear = :schoolYear)
              and (:difficulty is null or q.difficulty = :difficulty)
            order by q.createdAt asc
            """)
    List<QuestaoMaterial> buscarCandidatos(
            @Param("discipline") String discipline,
            @Param("subject") String subject,
            @Param("schoolYear") String schoolYear,
            @Param("difficulty") String difficulty,
            Pageable pageable
    );

    @Query("select distinct q.discipline from MaterialQuestion q where q.active = true order by q.discipline")
    List<String> listarDisciplinasDistintas();

    @Query("""
            select distinct q.subject from MaterialQuestion q
            where q.active = true and (:discipline is null or q.discipline = :discipline)
            order by q.subject
            """)
    List<String> listarAssuntosDistintos(@Param("discipline") String discipline);

    @Query("""
            select distinct q.schoolYear from MaterialQuestion q
            where q.active = true and (:discipline is null or q.discipline = :discipline)
            order by q.schoolYear
            """)
    List<String> listarAnosEscolaresDistintos(@Param("discipline") String discipline);

    @Query("""
            select distinct q.difficulty from MaterialQuestion q
            where q.active = true and (:discipline is null or q.discipline = :discipline)
            order by q.difficulty
            """)
    List<String> listarDificuldadesDistintas(@Param("discipline") String discipline);
}
