select * from SeasonStatus

CREATE TABLE SeasonStatus(
    status VARCHAR(20) NOT NULL CHECK (status IN ('ONGOING', 'FINISHED'))
);